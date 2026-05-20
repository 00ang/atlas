import AppIntents
import Foundation

public struct StartListeningIntent: AppIntent {
    public static let title: LocalizedStringResource = "Start Listening"
    public static let description = IntentDescription(
        "Listen to nearby audio and translate it into your chosen language."
    )

    public static let openAppWhenRun: Bool = true
    public static let isDiscoverable: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        AppGroup.sharedDefaults.set(false, forKey: AppGroup.DefaultsKey.stopRequested)
        AppGroup.sharedDefaults.set(UUID().uuidString, forKey: AppGroup.DefaultsKey.activeSessionID)
        return .result()
    }
}
