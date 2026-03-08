import SwiftUI

struct HomeView: View {
    @Environment(ChallengeStore.self) private var store

    private var todayEntry: DailyEntry? { store.entries[Date.todayKey()] }
    private var todaySteps: Int { todayEntry?.steps ?? 0 }
    private var todayKm: Double { todayEntry?.cyclingKm ?? 0.0 }

    private var dailyStepsFraction: Double {
        guard store.dailyGoal.steps > 0 else { return 0 }
        return Double(todaySteps) / Double(store.dailyGoal.steps)
    }

    private var dailyKmFraction: Double {
        guard store.dailyGoal.km > 0 else { return 0 }
        return todayKm / store.dailyGoal.km
    }

    private var weeklyStepsFraction: Double {
        Double(store.weeklySteps) / ProgressCalculator.stepGoal
    }

    private var weeklyKmFraction: Double {
        store.weeklyKm / ProgressCalculator.kmGoal
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Today
                    StatCard {
                        CardHeader("Today")
                        ActivityRow(
                            fraction: dailyStepsFraction,
                            systemImage: "figure.run",
                            value: todaySteps.formatted(),
                            goal: "\(store.dailyGoal.steps.formatted()) steps"
                        )
                        ActivityRow(
                            fraction: dailyKmFraction,
                            systemImage: "figure.outdoor.cycle",
                            value: String(format: "%.1f", todayKm),
                            goal: String(format: "%.1f km", store.dailyGoal.km)
                        )
                        ArcProgressBar(fraction: dailyStepsFraction + dailyKmFraction) {
                            ProgressLabel("Today", fraction: dailyStepsFraction + dailyKmFraction)
                        }
                        ArcProgressBar(fraction: store.weeklyProgress) {
                            ProgressLabel("Week", fraction: store.weeklyProgress)
                        }
                    }

                    // This Week
                    StatCard {
                        CardHeader("This Week")
                        ActivityRow(
                            fraction: weeklyStepsFraction,
                            systemImage: "figure.run",
                            value: store.weeklySteps.formatted(),
                            goal: "\(Int(ProgressCalculator.stepGoal).formatted()) steps"
                        )
                        ActivityRow(
                            fraction: weeklyKmFraction,
                            systemImage: "figure.outdoor.cycle",
                            value: String(format: "%.1f", store.weeklyKm),
                            goal: String(format: "%.1f km", ProgressCalculator.kmGoal)
                        )
                        ArcProgressBar(fraction: store.weeklyProgress) {
                            ProgressLabel("Combined", fraction: store.weeklyProgress)
                        }
                        HStack {
                            Spacer()
                            Text("\(store.remainingDays) day\(store.remainingDays == 1 ? "" : "s") remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Hourly activity
                    StatCard {
                        CardHeader("Today's Activity")
                        HourlyChartView(hourlyActivity: store.hourlyActivity)
                            .frame(height: 120)
                    }

                    // Week overview grid
                    StatCard {
                        CardHeader("Week Overview")
                        WeeklyGridView(
                            entries: store.currentWeekEntries(),
                            startWeekday: store.settings.challengeStartWeekday
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Fit")
        }
    }
}

// MARK: - Local helpers

private struct CardHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProgressLabel: View {
    let title: String
    let fraction: Double
    init(_ title: String, fraction: Double) {
        self.title = title
        self.fraction = fraction
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(String(format: "%.1f%%", min(fraction, 1) * 100))
        }
    }
}

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
