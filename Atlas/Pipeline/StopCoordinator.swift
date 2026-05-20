import AtlasShared
import Foundation

@MainActor
final class StopCoordinator {
    static let shared = StopCoordinator()

    private var defaultsObserver: NSObjectProtocol?
    private var darwinRegistered: Bool = false

    private init() {}

    func start() {
        guard !darwinRegistered else { return }
        darwinRegistered = true

        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, _, _, _, _ in
                Task { @MainActor in
                    await StopCoordinator.shared.handleStopRequest()
                }
            },
            AppGroup.darwinStopNotification,
            nil,
            .deliverImmediately
        )

        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: AppGroup.sharedDefaults,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if AppGroup.sharedDefaults.bool(forKey: AppGroup.DefaultsKey.stopRequested) {
                    await StopCoordinator.shared.handleStopRequest()
                }
            }
        }
    }

    private func handleStopRequest() async {
        await SessionPipeline.shared.stop(reason: .userRequested)
    }
}
