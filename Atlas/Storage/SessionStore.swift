import Foundation
import SwiftData

@MainActor
enum SessionStore {
    static func save(_ session: Session) throws {
        let container = try ModelContainer(for: Session.self)
        let context = container.mainContext
        context.insert(session)
        try context.save()
    }
}
