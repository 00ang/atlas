import AVFoundation
import Foundation
import Speech

@MainActor
final class SFSpeechRecognizerImpl: SpeechService {
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var restartTimer: Timer?
    private var accumulated: String = ""
    private var currentChunk: String = ""
    private var sourceLocale: Locale = Locale(identifier: "en-US")
    private var outputContinuation: AsyncStream<SpeechTranscript>.Continuation?
    private var bufferTask: Task<Void, Never>?

    func start(sourceLocale: Locale, buffers: AsyncStream<AVAudioPCMBuffer>) -> AsyncStream<SpeechTranscript> {
        self.sourceLocale = sourceLocale
        accumulated = ""
        currentChunk = ""

        let stream = AsyncStream<SpeechTranscript> { continuation in
            self.outputContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
        }

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                guard status == .authorized else {
                    self.outputContinuation?.finish()
                    return
                }
                self.startRecognition()
                self.bufferTask = Task { [weak self] in
                    for await buffer in buffers {
                        await self?.append(buffer)
                    }
                }
            }
        }

        return stream
    }

    func stop() {
        restartTimer?.invalidate()
        restartTimer = nil
        bufferTask?.cancel()
        bufferTask = nil
        finishCurrentChunk(emitFinal: true)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        recognizer = nil
        outputContinuation?.finish()
        outputContinuation = nil
    }

    private func startRecognition() {
        let recognizer = SFSpeechRecognizer(locale: sourceLocale) ?? SFSpeechRecognizer()
        guard let recognizer, recognizer.isAvailable else {
            outputContinuation?.finish()
            return
        }
        self.recognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        self.request = request
        currentChunk = ""

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.currentChunk = result.bestTranscription.formattedString
                    let combined = (self.accumulated + " " + self.currentChunk).trimmingCharacters(in: .whitespaces)
                    self.outputContinuation?.yield(SpeechTranscript(text: combined, isFinal: result.isFinal))
                    if result.isFinal {
                        self.accumulated = combined
                        self.currentChunk = ""
                    }
                }
                if error != nil {
                    self.rotateChunk()
                }
            }
        }

        restartTimer?.invalidate()
        restartTimer = Timer.scheduledTimer(withTimeInterval: 55, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.rotateChunk() }
        }
    }

    private func rotateChunk() {
        finishCurrentChunk(emitFinal: false)
        startRecognition()
    }

    private func finishCurrentChunk(emitFinal: Bool) {
        if !currentChunk.isEmpty {
            accumulated = (accumulated + " " + currentChunk).trimmingCharacters(in: .whitespaces)
            currentChunk = ""
        }
        if emitFinal {
            outputContinuation?.yield(SpeechTranscript(text: accumulated, isFinal: true))
        }
        request?.endAudio()
        task?.finish()
        task = nil
        request = nil
    }

    private func append(_ buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }
}
