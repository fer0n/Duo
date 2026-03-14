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
                    goalKm: daily.goalKm
                )

                // Page 2: Hourly chart
                HourlyChartView(hourlyActivity: store.hourlyActivity)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Hourly")

                // Page 3: Weekly bar chart
                WatchWeeklyChartView()

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
                              0, 0, 0, 0, 0, 3.2, 4.1, 7.8, 0, 0, 0, 0]

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

            // Populate past days of the current challenge week so the bar chart has data.
            let cal = Calendar.current
            let weekStart = cal.currentWeekStart(startingOn: store.settings.challengeStartWeekday)
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            let pastDayData: [(steps: Int, km: Double)] = [
                (8_500, 4.2), (6_200, 2.8), (9_100, 5.5),
                (5_800, 3.1), (7_400, 0.0), (4_300, 6.0)
            ]
            let todayStart = cal.startOfDay(for: .now)
            let todayIndex = max(0, min(cal.dateComponents([.day], from: weekStart, to: todayStart).day ?? 0, 6))
            var entries: [String: DailyEntry] = [:]
            for i in 0..<todayIndex {
                let date = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
                let key = fmt.string(from: date)
                let p = pastDayData[i % pastDayData.count]
                entries[key] = DailyEntry(id: key, steps: p.steps, cyclingKm: p.km, date: date)
            }
            entries[todayKey] = DailyEntry(id: todayKey, steps: s.steps, cyclingKm: s.km, date: .now)
            store.entries = entries
        }
}
