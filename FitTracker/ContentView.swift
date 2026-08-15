import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Stats", systemImage: Const.Symbol.steps) }
            SettingsView()
                .tabItem { Label("Settings", systemImage: Const.Symbol.gear) }
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
