import AVFoundation
import Foundation

struct SpeechTranscript: Sendable {
    let text: String
    let isFinal: Bool
}

protocol SpeechService: AnyObject {
    func start(
        sourceLocale: Locale,
        buffers: AsyncStream<AVAudioPCMBuffer>
    ) -> AsyncStream<SpeechTranscript>

    func stop()
}

enum SpeechServiceFactory {
    @MainActor
    static func make() -> SpeechService {
        if #available(iOS 26.0, *) {
            return SpeechAnalyzerImpl()
        } else {
            return SFSpeechRecognizerImpl()
        }
    }
}
