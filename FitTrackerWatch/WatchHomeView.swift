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
        NavigationStack {
            TabView {
                // Page 1: Today
                activityPage(
                    icon: "chevron.up.2",
                    progress: dailyProgress,
                    steps: todaySteps,
                    km: todayKm
                )
                .navigationTitle("Today")

                // Page 2: Hourly chart
                hourlyPage
                    .navigationTitle("Hourly")

                // Page 3: This week
                activityPage(
                    icon: "trophy",
                    progress: store.weeklyProgress,
                    steps: store.weeklySteps,
                    km: store.weeklyKm
                )
                .navigationTitle("Week")
            }
            .tabViewStyle(.verticalPage)
        }
    }

    @ViewBuilder
    private func activityPage(
        icon: String,
        progress: Double,
        steps: Int,
        km: Double
    ) -> some View {
        VStack(spacing: 5) {
            Gauge(value: min(progress, 1.0)) {
                Image(systemName: icon)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(progress >= 1.0 ? .green : .blue)
            .frame(width: 72, height: 72)

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 0) {
                GridRow {
                    Image(systemName: "figure.walk")
                        .foregroundStyle(.secondary)
                        .gridCellAnchor(.center)
                        .font(.caption)
                    HStack {
                        Text(steps.formatted())
                            .font(.title2).monospacedDigit()
                        Text("steps")
                            .foregroundStyle(.secondary)
                    }
                }
                GridRow {
                    Image(systemName: "figure.outdoor.cycle")
                        .foregroundStyle(.secondary)
                        .gridCellAnchor(.center)
                        .font(.caption)
                    HStack {
                        Text(String(format: "%.1f", km))
                            .font(.title2).monospacedDigit()
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.footnote)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hourlyPage: some View {
        let currentHour = Calendar.current.component(.hour, from: .now)
        let maxUnits = store.hourlyActivity.map(\.units).max() ?? 0

        return VStack(spacing: 8) {
            Chart(store.hourlyActivity) { item in
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
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...(maxUnits > 0 ? maxUnits * 1.2 : 0.01))

            Button("Refresh") {
                Task { await store.refreshFromHealthKit() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.mini)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    // Realistic day: quiet night, morning walk, lunch stroll, evening ride
    let hourlySteps = [0, 0, 0, 0, 0, 0, 80, 950, 1200, 400, 300, 200,
                       750, 600, 150, 200, 180, 300, 1100, 800, 400, 100, 50, 0]
    let hourlyKm: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 3.2, 4.1, 1.8, 0, 0, 0, 0]

    let store = ChallengeStore(skipHealthKit: true)
    let todayKey = Date.todayKey()
    store.entries = [
        todayKey: DailyEntry(id: todayKey, steps: 7250, cyclingKm: 9.1, date: .now)
    ]
    store.hourlyActivity = (0..<24).map { HourlyActivity(hour: $0, steps: hourlySteps[$0], km: hourlyKm[$0]) }
    return WatchHomeView()
        .environment(store)
}
