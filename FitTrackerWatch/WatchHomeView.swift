import SwiftUI

struct WatchHomeView: View {
    @Environment(ChallengeStore.self) private var store

    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            TabView {
                // Page 1: Today
                ActivityPageView(config: ActivityPageConfig(
                    label: "Today",
                    stepsFraction: store.dailyStepsFraction,
                    kmFraction: store.dailyKmFraction,
                    steps: store.todaySteps,
                    km: store.todayKm,
                    goalSteps: store.dailyGoal.steps,
                    goalKm: store.dailyGoal.km
                ))

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

                // Page 4: Refresh
                Button {
                    Task {
                        isRefreshing = true
                        await store.refreshFromHealthKit()
                        try? await Task.sleep(for: .seconds(0.2))
                        isRefreshing = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.trianglehead.counterclockwise")
                            .symbolEffect(.rotate, isActive: isRefreshing)
                        Text("Refresh")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(isRefreshing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.default, value: isRefreshing)
            }
            .tabViewStyle(.verticalPage)
        }
    }
}

#Preview {
    @Previewable @State var scenarioIndex = 1

    let scenarios: [(steps: Int, km: Double)] = [
        (0, 0),
        (3_000, 4.0),
        (8_000, 10.0),
        (15_000, 20.0),
        (22_000, 35.0),
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
