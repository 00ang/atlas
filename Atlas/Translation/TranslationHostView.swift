import SwiftUI
import Translation

struct TranslationHostView: View {
    let source: Locale
    let target: Locale
    let phrases: AsyncStream<String>
    let onTranslate: (String) -> Void

    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onAppear {
                configuration = TranslationSession.Configuration(
                    source: source.language,
                    target: target.language
                )
            }
            .translationTask(configuration) { session in
                do {
                    try await session.prepareTranslation()
                } catch {
                    return
                }
                for await phrase in phrases {
                    guard !phrase.isEmpty else { continue }
                    do {
                        let response = try await session.translate(phrase)
                        onTranslate(response.targetText)
                    } catch {
                        onTranslate(phrase)
                    }
                }
            }
    }
}
