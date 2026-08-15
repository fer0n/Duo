import SwiftUI
import WatchKit

@main
struct FitTrackerWatchApp: App {
    @State private var store = Self.makeStore()
    @Environment(\.scenePhase) private var scenePhase

    /// Screenshot tooling: launch with `-demoData` to fill the UI with realistic sample
    /// data instead of real HealthKit data (see `ChallengeStore.preview()`).
    private static func makeStore() -> ChallengeStore {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-demoData") {
            let store = ChallengeStore.preview()
            store.persistDemoSnapshotForWidgets()
            return store
        }
        #endif
        return ChallengeStore()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchHomeView()
            }
            .environment(store)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    store.saveSessionSnapshot()
                }
                guard phase == .active else { return }
                NotificationManager.shared.clearDeliveredNotifications()
                if !store.skipsHealthKit {
                    Task { await store.refreshFromHealthKit() }
                }
                scheduleBackgroundRefresh()
            }
        }
        .backgroundTask(.appRefresh("refresh")) {
            await store.refreshFromHealthKit()
            scheduleBackgroundRefresh()
        }
    }

    private nonisolated func scheduleBackgroundRefresh() {
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date(timeIntervalSinceNow: 15 * 60),
            userInfo: nil,
            scheduledCompletion: { _ in }
        )
    }
}
