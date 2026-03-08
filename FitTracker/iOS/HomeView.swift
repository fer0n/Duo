import SwiftUI

struct HomeView: View {
    @Environment(ChallengeStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ProgressRingView(progress: store.weeklyProgress)

                    WeekProgressSection(
                        weeklySteps: store.weeklySteps,
                        weeklyKm: store.weeklyKm
                    )

                    DailyTargetCard(
                        dailyTarget: ProgressCalculator.dailyTarget(
                            weeklyProgress: store.weeklyProgress,
                            remainingDays: store.remainingDays
                        ),
                        remainingDays: store.remainingDays
                    )

                    WeeklyGridSection(
                        entries: store.currentWeekEntries(),
                        startWeekday: store.settings.challengeStartWeekday
                    )
                }
                .padding()
            }
            .navigationTitle("FitChallenge")
        }
    }
}

#Preview {
    HomeView()
        .environment(ChallengeStore())
}
