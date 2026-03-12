import SwiftUI

private let bikeColor = Color.accentColor.mix(with: .black, by: 0.2)

struct HomeView: View {
    @Environment(ChallengeStore.self) private var store

    var body: some View {
        let daily = store.dailyContext
        let weekly = store.weeklyStats
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Today
                    StatCard {
                        CardHeader("Today")
                        ActivityRow(
                            fraction: daily.stepsFraction,
                            systemImage: "figure.run",
                            value: store.todaySteps.formatted(),
                            goal: "\(daily.goalSteps.formatted()) steps",
                            secondaryFraction: daily.stepsFraction + daily.kmFraction
                        )
                        ActivityRow(
                            fraction: daily.kmFraction,
                            systemImage: "figure.outdoor.cycle",
                            value: String(format: "%.1f", store.todayKm),
                            goal: String(format: "%.1f km", daily.goalKm),
                            secondaryFraction: daily.stepsFraction + daily.kmFraction
                        )
                        ArcProgressBar(
                            stepsFraction: daily.stepsFraction,
                            kmFraction: daily.kmFraction,
                            kmColor: bikeColor
                        ) {
                            ProgressLabel("Today", fraction: daily.stepsFraction + daily.kmFraction)
                        }
                        ArcProgressBar(
                            stepsFraction: weekly.stepsFraction,
                            kmFraction: weekly.kmFraction,
                            kmColor: bikeColor
                        ) {
                            ProgressLabel("Week", fraction: weekly.progress)
                        }
                    }

                    // This Week
                    StatCard {
                        CardHeader("This Week")
                        ActivityRow(
                            fraction: weekly.stepsFraction,
                            systemImage: "figure.run",
                            value: weekly.steps.formatted(),
                            goal: "\(Int(ProgressCalculator.stepGoal).formatted()) steps",
                            secondaryFraction: weekly.stepsFraction + weekly.kmFraction
                        )
                        ActivityRow(
                            fraction: weekly.kmFraction,
                            systemImage: "figure.outdoor.cycle",
                            value: String(format: "%.1f", weekly.km),
                            goal: String(format: "%.1f km", ProgressCalculator.kmGoal),
                            secondaryFraction: weekly.stepsFraction + weekly.kmFraction
                        )
                        ArcProgressBar(
                            stepsFraction: weekly.stepsFraction,
                            kmFraction: weekly.kmFraction,
                            kmColor: bikeColor
                        ) {
                            ProgressLabel("Combined", fraction: weekly.progress)
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
                            entries: weekly.entries,
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
