import SwiftUI

struct WatchHomeView: View {
    @Environment(ChallengeStore.self) private var store

    private var todayEntry: DailyEntry? { store.entries[Date.todayKey()] }
    private var todaySteps: Int { todayEntry?.steps ?? 0 }
    private var todayKm: Double { todayEntry?.cyclingKm ?? 0.0 }

    /// Daily target computed from previous days only — stays fixed as today's data accumulates.
    private var dailyGoal: (steps: Int, km: Double) {
        let prev = store.currentWeekEntries().filter { !Calendar.current.isDateInToday($0.date) }
        let prevProgress = ProgressCalculator.weeklyProgress(
            steps: prev.reduce(0) { $0 + $1.steps },
            km: prev.reduce(0.0) { $0 + $1.cyclingKm }
        )
        return ProgressCalculator.dailyTarget(weeklyProgress: prevProgress, remainingDays: store.remainingDays)
    }

    private var dailyStepsFraction: Double {
        guard dailyGoal.steps > 0 else { return 0 }
        return Double(todaySteps) / Double(dailyGoal.steps)
    }

    private var dailyKmFraction: Double {
        guard dailyGoal.km > 0 else { return 0 }
        return todayKm / dailyGoal.km
    }

    private var weeklyStepsFraction: Double {
        Double(store.weeklySteps) / ProgressCalculator.stepGoal
    }

    private var weeklyKmFraction: Double {
        store.weeklyKm / ProgressCalculator.kmGoal
    }

    var body: some View {
        NavigationStack {
            TabView {
                // Page 1: Today
                ActivityPageView(config: ActivityPageConfig(
                    label: "Today",
                    stepsFraction: dailyStepsFraction,
                    kmFraction: dailyKmFraction,
                    steps: todaySteps,
                    km: todayKm,
                    goalSteps: dailyGoal.steps,
                    goalKm: dailyGoal.km,
                    secondaryBar: ("Week", weeklyStepsFraction + weeklyKmFraction)
                ))

                // Page 2: Hourly chart
                WatchHourlyView(hourlyActivity: store.hourlyActivity)
                    .navigationTitle("Hourly")

                // Page 3: This week
                ActivityPageView(config: ActivityPageConfig(
                    label: "Week",
                    stepsFraction: weeklyStepsFraction,
                    kmFraction: weeklyKmFraction,
                    steps: store.weeklySteps,
                    km: store.weeklyKm,
                    goalSteps: Int(ProgressCalculator.stepGoal),
                    goalKm: ProgressCalculator.kmGoal
                ))

                // Page 4: Refresh
                Button("Refresh") {
                    Task { await store.refreshFromHealthKit() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tabViewStyle(.verticalPage)
        }
    }
}

#Preview {
    @Previewable @State var scenarioIndex = 0

    let scenarios: [(steps: Int, km: Double)] = [
        (0, 0),
        (3_000, 4.0),
        (8_000, 10.0),
        (15_000, 20.0),
        (22_000, 35.0)
    ]

    let hourlySteps = [0, 0, 0, 0, 0, 0, 80, 950, 1200, 400, 300, 200,
                       750, 600, 150, 200, 180, 300, 1100, 800, 400, 100, 50, 0]
    let hourlyKm: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 3.2, 4.1, 1.8, 0, 0, 0, 0]

    let store = ChallengeStore(skipHealthKit: true)
    let todayKey = Date.todayKey()

    WatchHomeView()
        .environment(store)
        .onChange(of: scenarioIndex) { _, idx in
            let s = scenarios[idx]
            withAnimation(.smooth) {
                store.entries[todayKey] = DailyEntry(id: todayKey, steps: s.steps, cyclingKm: s.km, date: .now)
            }
        }
        .overlay(alignment: .bottom) {
            Button {
                scenarioIndex = (scenarioIndex + 1) % scenarios.count
            } label: {
                Text("\(scenarioIndex + 1)/\(scenarios.count)")
                    .font(.system(size: 9, weight: .bold))
                    .padding(4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 2)
        }
        .onAppear {
            store.hourlyActivity = (0..<24).map { HourlyActivity(hour: $0, steps: hourlySteps[$0], km: hourlyKm[$0]) }
            store.entries = [todayKey: DailyEntry(id: todayKey, steps: 0, cyclingKm: 0, date: .now)]
        }
}
