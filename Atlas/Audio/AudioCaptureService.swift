import AVFoundation
import Foundation

@MainActor
final class AudioCaptureService {
    enum Event {
        case buffer(AVAudioPCMBuffer)
        case interrupted
        case resumed
        case ended
    }

    private let engine = AVAudioEngine()
    private var continuation: AsyncStream<Event>.Continuation?
    private var observers: [NSObjectProtocol] = []
    private var isActive: Bool = false

    var inputFormat: AVAudioFormat {
        engine.inputNode.outputFormat(forBus: 0)
    }

    func start() throws -> AsyncStream<Event> {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.allowBluetooth, .defaultToSpeaker, .mixWithOthers]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let format = engine.inputNode.outputFormat(forBus: 0)
        engine.inputNode.removeTap(onBus: 0)
        engine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            self?.continuation?.yield(.buffer(buffer))
        }

        engine.prepare()
        try engine.start()
        isActive = true

        let stream = AsyncStream<Event> { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
        }

        observeInterruptions()
        return stream
    }

    func stop() {
        guard isActive else { return }
        isActive = false
        engine.inputNode.removeTap(onBus: 0)
        if engine.isRunning { engine.stop() }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        for token in observers {
            NotificationCenter.default.removeObserver(token)
        }
        observers.removeAll()
        continuation?.yield(.ended)
        continuation?.finish()
        continuation = nil
    }

    private func observeInterruptions() {
        let center = NotificationCenter.default
        let interruption = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let userInfo = note.userInfo,
                  let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: rawType)
            else { return }
            switch type {
            case .began:
                self.continuation?.yield(.interrupted)
            case .ended:
                if let rawOpts = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let opts = AVAudioSession.InterruptionOptions(rawValue: rawOpts)
                    if opts.contains(.shouldResume) {
                        try? self.engine.start()
                        self.continuation?.yield(.resumed)
                    }
                }
            @unknown default:
                break
            }
        }
        observers.append(interruption)

        let routeChange = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.isActive, !self.engine.isRunning {
                try? self.engine.start()
            }
        }
        observers.append(routeChange)
    }
}
