//
//  FitTrackerApp.swift
//  FitTracker
//

import SwiftUI

@main
struct FitTrackerApp: App {
    @State private var store = ChallengeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
