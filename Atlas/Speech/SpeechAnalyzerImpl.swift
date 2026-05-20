import AVFoundation
import Foundation
import Speech

// iOS 26+ SpeechAnalyzer wrapper. The framework's symbols changed between
// betas; this file isolates the iOS-26 path so the iOS-18 build path is
// unaffected. On iOS 18-25 the factory in SpeechService.swift picks
// SFSpeechRecognizerImpl instead.
@available(iOS 26.0, *)
@MainActor
final class SpeechAnalyzerImpl: SpeechService {
    private var fallback: SFSpeechRecognizerImpl?

    func start(sourceLocale: Locale, buffers: AsyncStream<AVAudioPCMBuffer>) -> AsyncStream<SpeechTranscript> {
        // TODO: replace with SpeechAnalyzer API once the iOS 26 surface
        // ships. For now, route through SFSpeechRecognizer so behavior is
        // identical and the rest of the pipeline stays the same.
        let impl = SFSpeechRecognizerImpl()
        fallback = impl
        return impl.start(sourceLocale: sourceLocale, buffers: buffers)
    }

    func stop() {
        fallback?.stop()
        fallback = nil
    }
}
