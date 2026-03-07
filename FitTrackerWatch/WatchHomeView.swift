import SwiftUI
import Charts

struct WatchHomeView: View {
    @Environment(ChallengeStore.self) private var store

    private var todayEntry: DailyEntry? { store.entries[Date.todayKey()] }
    private var todaySteps: Int { todayEntry?.steps ?? 0 }
    private var todayKm: Double { todayEntry?.cyclingKm ?? 0.0 }

    private var dailyGoal: (steps: Int, km: Double) {
        ProgressCalculator.dailyTarget(
            weeklyProgress: store.weeklyProgress,
            remainingDays: store.remainingDays
        )
    }

    private var dailyProgress: Double {
        let goalUnits = Double(dailyGoal.steps) / ProgressCalculator.stepGoal
            + dailyGoal.km / ProgressCalculator.kmGoal
        guard goalUnits > 0 else { return store.weeklyProgress >= 1.0 ? 1.0 : 0.0 }
        let todayUnits = Double(todaySteps) / ProgressCalculator.stepGoal
            + todayKm / ProgressCalculator.kmGoal
        return min(todayUnits / goalUnits, 1.0)
    }

    var body: some View {
        List {
            Section("Today") {
                activitySection(
                    icon: "figure.walk",
                    progress: dailyProgress,
                    steps: todaySteps,
                    km: todayKm
                )
            }

            Section("Hourly") {
                hourlyChart
            }

            Section("This week") {
                activitySection(
                    icon: "trophy",
                    progress: store.weeklyProgress,
                    steps: store.weeklySteps,
                    km: store.weeklyKm
                )
            }

            Section {
                Button("Refresh") {
                    Task { await store.refreshFromHealthKit() }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.carousel)
    }

    @ViewBuilder
    private func activitySection(
        icon: String,
        progress: Double,
        steps: Int,
        km: Double
    ) -> some View {
        HStack(spacing: 8) {
            Gauge(value: min(progress, 1.0)) {
                Image(systemName: icon)
                    .font(.caption2)
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(progress >= 1.0 ? .green : .blue)
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Label(steps.formatted() + " steps", systemImage: "figure.walk")
                    .font(.caption2)
                Label(String(format: "%.1f km", km), systemImage: "bicycle")
                    .font(.caption2)
            }
        }
    }

    private var hourlyChart: some View {
        let currentHour = Calendar.current.component(.hour, from: .now)
        let maxUnits = store.hourlyActivity.map(\.units).max() ?? 0

        return Chart(store.hourlyActivity) { item in
            BarMark(
                x: .value("Hour", item.hour),
                y: .value("Activity", item.units)
            )
            .foregroundStyle(item.hour == currentHour ? Color.blue : Color.blue.opacity(0.35))
        }
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text("\(hour)")
                            .font(.system(size: 7))
                    }
                }
            }
        }
        .padding()
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(maxUnits > 0 ? maxUnits * 1.2 : 0.01))
        .frame(height: 60)
    }
}

#Preview {
    NavigationStack {
        WatchHomeView()
    }
    .environment(ChallengeStore())
}
