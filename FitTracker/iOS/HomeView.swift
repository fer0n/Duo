import SwiftUI

struct HomeView: View {
    @Environment(ChallengeStore.self) private var store

    var body: some View {
        let daily = store.dailyContext
        let weekly = store.weeklyStats
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Today — uses shared WatchGaugeView
                    WatchGaugeView(
                        stepsFraction: daily.stepsFraction,
                        kmFraction: daily.kmFraction,
                        todaySteps: store.todaySteps,
                        todayKm: store.todayKm,
                        goalSteps: daily.goalSteps,
                        goalKm: daily.goalKm,
                        isWeeklyGoalReached: weekly.progress >= 1.0
                    )
                    .padding()
                    .padding(.bottom)

                    // Daily chart — shared DailyChartView
                    StatCard {
                        Text(store.dailyChartLabel)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DailyChartView()
                            .frame(height: 160)
                    }

                    // Hourly activity
                    StatCard {
                        Text("Hourly")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HourlyChartView(hourlyActivity: store.hourlyActivity)
                            .frame(height: 120)
                    }

                    // This Week — shared ActivityPageView
                    StatCard {
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
                }
                .padding()
            }
        }
        .onAppear { store.markGoalsSeen() }
    }
}

// MARK: - Local helpers

private struct StatCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

    HomeView()
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
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .onAppear {
            store.hourlyActivity = (0..<24).map { HourlyActivity(hour: $0, steps: hourlySteps[$0], km: hourlyKm[$0]) }
            store.entries = [todayKey: DailyEntry(id: todayKey, steps: 0, cyclingKm: 0, date: .now)]
        }
}
