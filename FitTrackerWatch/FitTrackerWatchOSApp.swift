import SwiftUI
import WatchKit

@main
struct FitTrackerWatchApp: App {
    @State private var store = ChallengeStore()
    @Environment(\.scenePhase) private var scenePhase

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
                Task { await store.refreshFromHealthKit() }
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
