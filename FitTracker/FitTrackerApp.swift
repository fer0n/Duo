//
//  FitTrackerApp.swift
//  FitTracker
//

import SwiftUI

@main
struct FitTrackerApp: App {
    @State private var store = ChallengeStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                store.saveSessionSnapshot()
            }
        }
    }
}
