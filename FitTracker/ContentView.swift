import SwiftUI

struct ContentView: View {
    @AppStorage(AppGroup.hasSeenWelcomeKey, store: AppGroup.defaults)
    private var hasSeenWelcome = false

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
        .sheet(isPresented: Binding(get: { !hasSeenWelcome }, set: { hasSeenWelcome = !$0 })) {
            WelcomeView()
        }
    }
}

#Preview {
    ContentView()
        .environment(ChallengeStore())
}
