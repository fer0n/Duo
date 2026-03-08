import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Challenge", systemImage: "figure.run") }
            DataEntryView()
                .tabItem { Label("Log", systemImage: "plus.circle") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

#Preview {
    ContentView()
        .environment(ChallengeStore())
}
