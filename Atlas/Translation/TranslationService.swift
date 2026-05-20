import Foundation

@MainActor
final class TranslationService {
    private let host: HiddenTranslationHost
    private let inputContinuation: AsyncStream<String>.Continuation
    let translations: AsyncStream<String>

    init(sourceLocale: Locale, targetLocale: Locale) {
        let (phrases, phrasesContinuation) = AsyncStream<String>.makeStream()
        self.inputContinuation = phrasesContinuation
        let (output, outputContinuation) = AsyncStream<String>.makeStream()
        self.translations = output

        self.host = HiddenTranslationHost(
            source: sourceLocale,
            target: targetLocale,
            phrases: phrases
        ) { translated in
            outputContinuation.yield(translated)
        }
        host.attach()
    }

    func translate(_ phrase: String) {
        inputContinuation.yield(phrase)
    }

    func stop() {
        inputContinuation.finish()
        host.detach()
    }
}
