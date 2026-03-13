import SwiftUI

struct WatchHomeView: View {
    @Environment(ChallengeStore.self) private var store

    var body: some View {
        NavigationStack {
            TabView {
                // Page 1: Today
                WatchGaugeView(
                    stepsFraction: store.dailyStepsFraction,
                    kmFraction: store.dailyKmFraction,
                    todaySteps: store.todaySteps,
                    todayKm: store.todayKm,
                    goalSteps: store.dailyGoal.steps,
                    goalKm: store.dailyGoal.km
                )

                // Page 2: Hourly chart
                HourlyChartView(hourlyActivity: store.hourlyActivity)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Hourly")

                // Page 3: This week
                ActivityPageView(config: ActivityPageConfig(
                    label: "Week",
                    stepsFraction: store.weeklyStepsFraction,
                    kmFraction: store.weeklyKmFraction,
                    steps: store.weeklySteps,
                    km: store.weeklyKm,
                    goalSteps: Int(ProgressCalculator.stepGoal),
                    goalKm: ProgressCalculator.kmGoal
                ))
            }
            .tabViewStyle(.verticalPage)
        }
    }
}

#Preview {
    @Previewable @State var scenarioIndex = 0

    let scenarios: [(steps: Int, km: Double)] = [
        //        (1000, 1.4),
        //        (2300, 4.3),
        //        (3500, 1.1)
        (0, 0),
        (1_000, 1.0),
        (4_200, 2.6),
        (5_000, 0),
        (0, 3.0),
        (22_000, 40.0)
    ]

    let hourlySteps = [0, 0, 0, 0, 0, 0, 80, 950, 1200, 400, 300, 200,
                       750, 600, 150, 200, 180, 300, 1100, 800, 400, 100, 50, 0]
    let hourlyKm: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 3.2, 4.1, 1.8, 0, 0, 0, 0]

    let store = ChallengeStore(skipHealthKit: true)
    let todayKey = Date.todayKey()

    WatchHomeView()
        .environment(store)
        .task(id: scenarioIndex) {
            let s = scenarios[scenarioIndex]
            withAnimation(.smooth) {
                store.entries[todayKey] = DailyEntry(id: todayKey, steps: s.steps, cyclingKm: s.km, date: .now)
            }
        }
        .overlay(alignment: .top) {
            Button {
                scenarioIndex = (scenarioIndex + 1) % scenarios.count
            } label: {
                Text("\(scenarioIndex + 1)/\(scenarios.count)")
                    .font(.system(size: 9, weight: .bold))
                    .padding(4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, -40)
            .padding(.bottom, 2)
        }
        .onAppear {
            let s = scenarios[scenarioIndex]
            store.hourlyActivity = (0..<24).map { HourlyActivity(hour: $0, steps: hourlySteps[$0], km: hourlyKm[$0]) }
            store.entries = [todayKey: DailyEntry(id: todayKey, steps: s.steps, cyclingKm: s.km, date: .now)]
        }
}
