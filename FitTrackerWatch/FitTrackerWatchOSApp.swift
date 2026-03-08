//
//  FitTrackerWatchOSApp.swift
//  FitTrackerWatchOS Watch App
//

import SwiftUI

@main
struct FitTrackerWatchApp: App {
    @State private var store = ChallengeStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchHomeView()
            }
            .environment(store)
        }
    }
}
