import ActivityKit
import Foundation

public struct AtlasListeningAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var originalPreview: String
        public var translatedPreview: String
        public var sourceLocaleCode: String
        public var targetLocaleCode: String
        public var isTranslating: Bool
        public var statusMessage: String?

        public init(
            originalPreview: String = "",
            translatedPreview: String = "",
            sourceLocaleCode: String = "",
            targetLocaleCode: String = "",
            isTranslating: Bool = false,
            statusMessage: String? = nil
        ) {
            self.originalPreview = originalPreview
            self.translatedPreview = translatedPreview
            self.sourceLocaleCode = sourceLocaleCode
            self.targetLocaleCode = targetLocaleCode
            self.isTranslating = isTranslating
            self.statusMessage = statusMessage
        }
    }

    public let sessionID: UUID
    public let startedAt: Date

    public init(sessionID: UUID, startedAt: Date) {
        self.sessionID = sessionID
        self.startedAt = startedAt
    }
}
