import ActivityKit
import AtlasShared
import Foundation

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var activity: Activity<AtlasListeningAttributes>?

    private init() {}

    func start(sessionID: UUID, sourceLocale: String, targetLocale: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = AtlasListeningAttributes(sessionID: sessionID, startedAt: .now)
        let state = AtlasListeningAttributes.ContentState(
            originalPreview: "",
            translatedPreview: "",
            sourceLocaleCode: sourceLocale,
            targetLocaleCode: targetLocale,
            isTranslating: false,
            statusMessage: "Listening…"
        )
        do {
            let content = ActivityContent(state: state, staleDate: nil)
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func update(originalPreview: String, translatedPreview: String, isTranslating: Bool, status: String? = nil) {
        guard let activity else { return }
        let state = AtlasListeningAttributes.ContentState(
            originalPreview: previewTrim(originalPreview),
            translatedPreview: previewTrim(translatedPreview),
            sourceLocaleCode: activity.content.state.sourceLocaleCode,
            targetLocaleCode: activity.content.state.targetLocaleCode,
            isTranslating: isTranslating,
            statusMessage: status
        )
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        guard let activity else { return }
        let state = activity.content.state
        Task {
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }

    private func previewTrim(_ text: String) -> String {
        guard text.count > 140 else { return text }
        let suffix = text.suffix(140)
        return "…" + String(suffix)
    }
}
