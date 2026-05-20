import Foundation
import UserNotifications

enum NotificationService {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func postCompletion(sessionID: UUID, body: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = "Atlas translation"
        content.body = truncated(body)
        content.userInfo = ["sessionId": sessionID.uuidString]
        content.sound = .default
        content.interruptionLevel = .active

        let request = UNNotificationRequest(
            identifier: "atlas.session.\(sessionID.uuidString)",
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }

    private static func truncated(_ text: String) -> String {
        guard text.count > 250 else { return text }
        return String(text.prefix(247)) + "…"
    }
}
