import AppIntents
import Foundation

public struct StopListeningIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Stop Listening"
    public static let description = IntentDescription("Stop the current Atlas listening session.")

    public static let openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        AppGroup.sharedDefaults.set(true, forKey: AppGroup.DefaultsKey.stopRequested)
        AppGroup.sharedDefaults.synchronize()
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(AppGroup.darwinStopNotification),
            nil,
            nil,
            true
        )
        return .result()
    }
}
