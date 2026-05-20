import AVFoundation
import AtlasShared
import Foundation
import NaturalLanguage
import SwiftUI

@MainActor
final class SessionPipeline: ObservableObject {
    static let shared = SessionPipeline()

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var originalTranscript: String = ""
    @Published private(set) var translatedTranscript: String = ""

    private let audio = AudioCaptureService()
    private var speech: SpeechService?
    private var translation: TranslationService?
    private var translationTask: Task<Void, Never>?
    private let liveActivity = LiveActivityService.shared

    private var sessionID: UUID = UUID()
    private var startedAt: Date = .now
    private var sourceLocale: Locale = Locale(identifier: "en-US")
    private var targetLocale: Locale = Locale(identifier: "en-US")
    private var languageDetected: Bool = false
    private var lastTranslatedLength: Int = 0
    private var lastBufferAt: Date = .now

    private var tasks: [Task<Void, Never>] = []
    private var silenceTimer: Timer?
    private var hardCapTimer: Timer?

    private init() {}

    func start(sessionIDString: String? = nil) async {
        guard !isRunning else { return }

        let defaults = AppGroup.sharedDefaults
        let targetCode = UserDefaults.standard.string(forKey: "atlas.targetLocale")
            ?? Locale.current.language.languageCode?.identifier
            ?? "en"
        targetLocale = Locale(identifier: targetCode)

        let lastSource = defaults.string(forKey: AppGroup.DefaultsKey.lastSourceLocale) ?? "en-US"
        sourceLocale = Locale(identifier: lastSource)

        sessionID = sessionIDString.flatMap(UUID.init(uuidString:)) ?? UUID()
        startedAt = .now
        originalTranscript = ""
        translatedTranscript = ""
        languageDetected = false
        lastTranslatedLength = 0
        lastBufferAt = .now

        defaults.set(false, forKey: AppGroup.DefaultsKey.stopRequested)
        defaults.set(sessionID.uuidString, forKey: AppGroup.DefaultsKey.activeSessionID)

        await NotificationService.requestAuthorizationIfNeeded()

        let speech = SpeechServiceFactory.make()
        self.speech = speech

        liveActivity.start(
            sessionID: sessionID,
            sourceLocale: sourceLocale.identifier,
            targetLocale: targetLocale.identifier
        )
        startTranslation(source: sourceLocale, target: targetLocale)

        let audioStream: AsyncStream<AudioCaptureService.Event>
        do {
            audioStream = try audio.start()
        } catch {
            liveActivity.end()
            translation?.stop()
            translation = nil
            defaults.removeObject(forKey: AppGroup.DefaultsKey.activeSessionID)
            return
        }

        let (buffers, bufferContinuation) = AsyncStream<AVAudioPCMBuffer>.makeStream()
        let speechStream = speech.start(sourceLocale: sourceLocale, buffers: buffers)

        isRunning = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        tasks.append(Task { [weak self] in
            for await event in audioStream {
                guard let self else { return }
                switch event {
                case .buffer(let buffer):
                    bufferContinuation.yield(buffer)
                    await self.handleBuffer(buffer)
                case .interrupted:
                    self.liveActivity.update(
                        originalPreview: self.originalTranscript,
                        translatedPreview: self.translatedTranscript,
                        isTranslating: false,
                        status: "Paused"
                    )
                case .resumed:
                    self.liveActivity.update(
                        originalPreview: self.originalTranscript,
                        translatedPreview: self.translatedTranscript,
                        isTranslating: false,
                        status: "Listening…"
                    )
                case .ended:
                    bufferContinuation.finish()
                }
            }
            bufferContinuation.finish()
        })

        tasks.append(Task { [weak self] in
            for await transcript in speechStream {
                await self?.handleTranscript(transcript)
            }
        })

        scheduleTimers()
    }

    private func startTranslation(source: Locale, target: Locale) {
        translation?.stop()
        translationTask?.cancel()

        let service = TranslationService(sourceLocale: source, targetLocale: target)
        translation = service
        translationTask = Task { [weak self] in
            for await translated in service.translations {
                await self?.handleTranslation(translated)
            }
        }
    }

    private func scheduleTimers() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRunning else { return }
                let elapsed = Date.now.timeIntervalSince(self.lastBufferAt)
                if elapsed > 5 && !self.originalTranscript.isEmpty {
                    await self.stop(reason: .silence)
                }
            }
        }

        hardCapTimer?.invalidate()
        hardCapTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: false) { [weak self] _ in
            Task { @MainActor in await self?.stop(reason: .hardCap) }
        }
    }

    private func handleBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))
        if rms > 0.005 {
            lastBufferAt = .now
        }
    }

    private func handleTranscript(_ transcript: SpeechTranscript) async {
        originalTranscript = transcript.text

        if !languageDetected, transcript.text.count > 20 {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(transcript.text)
            if let language = recognizer.dominantLanguage {
                let detected = Locale(identifier: language.rawValue)
                sourceLocale = detected
                AppGroup.sharedDefaults.set(detected.identifier, forKey: AppGroup.DefaultsKey.lastSourceLocale)
                languageDetected = true
                startTranslation(source: detected, target: targetLocale)
                lastTranslatedLength = 0
            }
        }

        let newSlice = String(transcript.text.dropFirst(lastTranslatedLength))
        if transcript.isFinal, !newSlice.trimmingCharacters(in: .whitespaces).isEmpty {
            translation?.translate(newSlice)
            lastTranslatedLength = transcript.text.count
        }

        liveActivity.update(
            originalPreview: transcript.text,
            translatedPreview: translatedTranscript,
            isTranslating: !translatedTranscript.isEmpty,
            status: "Listening…"
        )
    }

    private func handleTranslation(_ translated: String) async {
        let trimmed = translated.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if translatedTranscript.isEmpty {
            translatedTranscript = trimmed
        } else {
            translatedTranscript += " " + trimmed
        }
        liveActivity.update(
            originalPreview: originalTranscript,
            translatedPreview: translatedTranscript,
            isTranslating: true,
            status: "Listening…"
        )
    }

    enum StopReason {
        case userRequested, silence, hardCap, failure
    }

    func stop(reason: StopReason) async {
        guard isRunning else { return }
        isRunning = false

        silenceTimer?.invalidate()
        silenceTimer = nil
        hardCapTimer?.invalidate()
        hardCapTimer = nil

        for task in tasks { task.cancel() }
        tasks.removeAll()
        translationTask?.cancel()
        translationTask = nil

        speech?.stop()
        speech = nil
        audio.stop()
        translation?.stop()
        translation = nil

        let session = Session(
            id: sessionID,
            startedAt: startedAt,
            endedAt: .now,
            sourceLocale: sourceLocale.identifier,
            targetLocale: targetLocale.identifier,
            originalTranscript: originalTranscript,
            translatedTranscript: translatedTranscript
        )
        try? SessionStore.save(session)

        liveActivity.end()

        let defaults = AppGroup.sharedDefaults
        defaults.removeObject(forKey: AppGroup.DefaultsKey.activeSessionID)
        defaults.set(false, forKey: AppGroup.DefaultsKey.stopRequested)

        let notificationsEnabled = UserDefaults.standard.object(forKey: "atlas.notificationsEnabled") as? Bool ?? true
        if notificationsEnabled, reason != .failure {
            let body = translatedTranscript.isEmpty ? originalTranscript : translatedTranscript
            if !body.isEmpty {
                await NotificationService.postCompletion(sessionID: sessionID, body: body)
            }
        }
    }
}
