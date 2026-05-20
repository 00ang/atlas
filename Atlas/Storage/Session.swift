import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var sourceLocale: String
    var targetLocale: String
    var originalTranscript: String
    var translatedTranscript: String

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        endedAt: Date? = nil,
        sourceLocale: String,
        targetLocale: String,
        originalTranscript: String = "",
        translatedTranscript: String = ""
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.sourceLocale = sourceLocale
        self.targetLocale = targetLocale
        self.originalTranscript = originalTranscript
        self.translatedTranscript = translatedTranscript
    }
}
