import AtlasShared
import SwiftData
import SwiftUI
import UserNotifications

@main
struct AtlasApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var router = AppRouter()
    @StateObject private var pipeline = SessionPipeline.shared

    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Session.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(pipeline)
                .onOpenURL { url in router.handle(url: url) }
                .task { await router.handleLaunchIfNeeded(pipeline: pipeline) }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await router.handleLaunchIfNeeded(pipeline: pipeline) }
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

@MainActor
final class AppRouter: ObservableObject {
    enum Route: Hashable {
        case history
        case session(UUID)
        case bootstrap
    }

    @Published var route: Route = .history
    @Published var pendingSessionID: UUID?

    func handle(url: URL) {
        guard let link = DeepLink(url: url) else { return }
        switch link {
        case .session(let id):
            route = .session(id)
        }
    }

    func handleLaunchIfNeeded(pipeline: SessionPipeline) async {
        let defaults = AppGroup.sharedDefaults
        let activeID = defaults.string(forKey: AppGroup.DefaultsKey.activeSessionID)
        let stopRequested = defaults.bool(forKey: AppGroup.DefaultsKey.stopRequested)

        if let activeID, !stopRequested, !pipeline.isRunning {
            route = .bootstrap
            await pipeline.start(sessionIDString: activeID)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    nonisolated func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MainActor.assumeIsolated {
            UNUserNotificationCenter.current().delegate = self
            StopCoordinator.shared.start()
        }
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard
            let idString = response.notification.request.content.userInfo["sessionId"] as? String,
            let id = UUID(uuidString: idString)
        else { return }
        Task { @MainActor in
            UIApplication.shared.open(DeepLink.session(id: id).url)
        }
    }
}
