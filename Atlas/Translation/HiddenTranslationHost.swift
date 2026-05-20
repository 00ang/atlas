import SwiftUI
import UIKit

@MainActor
final class HiddenTranslationHost {
    private let source: Locale
    private let target: Locale
    private let phrases: AsyncStream<String>
    private let onTranslate: (String) -> Void
    private var window: UIWindow?

    init(
        source: Locale,
        target: Locale,
        phrases: AsyncStream<String>,
        onTranslate: @escaping (String) -> Void
    ) {
        self.source = source
        self.target = target
        self.phrases = phrases
        self.onTranslate = onTranslate
    }

    func attach() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState != .unattached }) ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        else { return }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = UIWindow.Level.alert - 1
        window.alpha = 0.0
        window.isUserInteractionEnabled = false
        window.frame = CGRect(x: 0, y: 0, width: 1, height: 1)

        let host = UIHostingController(
            rootView: TranslationHostView(
                source: source,
                target: target,
                phrases: phrases,
                onTranslate: onTranslate
            )
        )
        host.view.backgroundColor = .clear
        host.view.frame = window.bounds

        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }

    func detach() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
    }
}
