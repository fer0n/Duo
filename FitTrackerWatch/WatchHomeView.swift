import SwiftUI

struct WatchHomeView: View {
    @Environment(ChallengeStore.self) private var store

    var body: some View {
        let daily = store.dailyContext
        let weekly = store.weeklyStats
        NavigationStack {
            TabView {
                // Page 1: Today
                WatchGaugeView(
                    stepsFraction: daily.stepsFraction,
                    kmFraction: daily.kmFraction,
                    todaySteps: store.todaySteps,
                    todayKm: store.todayKm,
                    goalSteps: daily.goalSteps,
                    goalKm: daily.goalKm,
                    isWeeklyGoalReached: weekly.progress >= 1.0
                )

                // Page 2: Weekly bar chart
                WatchDailyChartView()

                // Page 3: Hourly chart
                HourlyChartView(hourlyActivity: store.hourlyActivity)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Hourly")

                // Page 4: This week
                ActivityPageView(config: ActivityPageConfig(
                    label: "Week",
                    stepsFraction: weekly.stepsFraction,
                    kmFraction: weekly.kmFraction,
                    steps: weekly.steps,
                    km: weekly.km,
                    goalSteps: Int(ProgressCalculator.stepGoal),
                    goalKm: ProgressCalculator.kmGoal
                ))
            }
            .tabViewStyle(.verticalPage)
        }
        .onAppear { store.markGoalsSeen() }
    }
}

#Preview {
    @Previewable @State var scenarioIndex = 0

    let store = ChallengeStore.preview(
        steps: ChallengeStore.previewScenarios[0].steps,
        km: ChallengeStore.previewScenarios[0].km
    )
    let todayKey = Date.todayKey()

    WatchHomeView()
        .environment(store)
        .task(id: scenarioIndex) {
            let s = ChallengeStore.previewScenarios[scenarioIndex]
            withAnimation(.smooth) {
                store.entries[todayKey] = DailyEntry(id: todayKey, steps: s.steps, cyclingKm: s.km, date: .now)
            }
        }
        .overlay(alignment: .top) {
            Button {
                scenarioIndex = (scenarioIndex + 1) % ChallengeStore.previewScenarios.count
            } label: {
                Text("\(scenarioIndex + 1)/\(ChallengeStore.previewScenarios.count)")
                    .font(.system(size: 9, weight: .bold))
                    .padding(4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, -40)
            .padding(.bottom, 2)
        }
}
