import Foundation

public enum AppGroup {
    public static let identifier = "group.com.atlas.app"

    public enum DefaultsKey {
        public static let stopRequested = "atlas.stopRequested"
        public static let activeSessionID = "atlas.activeSessionID"
        public static let pendingTranscript = "atlas.pendingTranscript"
        public static let pendingTranslation = "atlas.pendingTranslation"
        public static let lastSourceLocale = "atlas.lastSourceLocale"
    }

    public static let darwinStopNotification = "com.atlas.stop" as CFString

    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
