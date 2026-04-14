import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Stats", systemImage: "figure.run") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .safeAreaBar(edge: .top) {
            Color.black.opacity(0.0000001).frame(width: 1, height: 1)
        }
    }
}

#Preview {
    ContentView()
        .environment(ChallengeStore())
}
