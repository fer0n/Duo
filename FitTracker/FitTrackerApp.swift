//
//  FitTrackerApp.swift
//  FitTracker
//

import SwiftUI
import BackgroundTasks

@main
struct FitTrackerApp: App {
    @State private var store = ChallengeStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Both must happen before the app finishes launching (Apple requirement).
        NotificationManager.shared.becomeNotificationDelegate()

        // Register before the first runloop tick (Apple requirement).
        // The handler creates its own store instance since this closure may be
        // called when the app is launched in the background.
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: NotificationManager.dailyReminderTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            let store = ChallengeStore(skipHealthKit: true)
            Task { await store.handleDailyReminderTask(refreshTask) }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                store.saveSessionSnapshot()
            }
            if phase == .active {
                NotificationManager.shared.clearDeliveredNotifications()
            }
        }
    }
}
