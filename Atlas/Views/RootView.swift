import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var pipeline: SessionPipeline

    var body: some View {
        Group {
            switch router.route {
            case .bootstrap:
                BootstrapView()
            case .history:
                NavigationStack {
                    HistoryView()
                }
            case .session(let id):
                NavigationStack {
                    SessionDetailLoader(id: id)
                }
            }
        }
        .onChange(of: pipeline.isRunning) { _, running in
            if !running, case .bootstrap = router.route {
                router.route = .history
            }
        }
    }
}

private struct SessionDetailLoader: View {
    let id: UUID
    @Query private var sessions: [Session]

    init(id: UUID) {
        self.id = id
        let predicate = #Predicate<Session> { $0.id == id }
        _sessions = Query(filter: predicate)
    }

    var body: some View {
        if let session = sessions.first {
            SessionDetailView(session: session)
        } else {
            ContentUnavailableView("Session not found", systemImage: "questionmark.circle")
        }
    }
}
