import AppIntents

struct FitTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetDailyRemainingIntent(),
            phrases: [
                "Get daily remaining in \(.applicationName)",
                "How much is left today in \(.applicationName)"
            ],
            shortTitle: "Daily Remaining",
            systemImageName: "figure.walk.circle"
        )
    }
}
