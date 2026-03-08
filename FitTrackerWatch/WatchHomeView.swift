import SwiftUI
import Charts

// MARK: - ArcShape

private struct ArcShape: Shape {
    var fraction: Double    // unbounded; >1.0 draws overlapping laps

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard fraction > 0 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        let fullLaps = Int(fraction)
        let remainder = fraction - Double(fullLaps)
        for _ in 0..<fullLaps {
            path.addArc(center: center, radius: radius,
                        startAngle: .degrees(-90), endAngle: .degrees(270), clockwise: false)
        }
        if remainder > 0 {
            path.addArc(center: center, radius: radius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * remainder),
                        clockwise: false)
        }
        return path
    }
}

// MARK: - SingleArcGauge

struct SingleArcGauge: View {
    var fraction: Double    // raw, unbounded (>1.0 = overflow/lap)
    var systemImage: String

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = max(size * 0.14, 4)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: lineWidth)

                ArcShape(fraction: fraction)
                    .stroke(Color.accentColor,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                Image(systemName: systemImage)
                    .font(.system(size: size * 0.36, weight: .black))
            }
            .padding(lineWidth / 2)
            .frame(width: size, height: size)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .animation(.smooth, value: fraction)
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - ActivityRow

struct ActivityRow: View {
    var fraction: Double
    var systemImage: String
    var value: String
    var goal: String

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            SingleArcGauge(fraction: fraction, systemImage: systemImage)
                .frame(width: 45, height: 45)

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text(value)
                    .font(.title).monospacedDigit()
                    .minimumScaleFactor(0.01)
                    .lineLimit(1)
                    .padding(.vertical, -7)
                    .contentTransition(.numericText())

                Text(goal)
                    .font(.footnote).monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .fontWeight(.bold)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - ProgressCapsule

private struct ProgressCapsule: Shape {
    var fraction: Double    // clamped to 0...1 before use

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let width = max(rect.height, CGFloat(fraction) * rect.width)
        return Capsule().path(in: CGRect(x: rect.minX, y: rect.minY,
                                         width: width, height: rect.height))
    }
}

// MARK: - ArcProgressBar

struct ArcProgressBar<Label: View>: View {
    var fraction: Double    // clamped to 0...1 for display
    @ViewBuilder var label: () -> Label

    private var clampedFraction: Double { min(max(fraction, 0), 1) }

    var body: some View {
        VStack(spacing: 2) {
            label()

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.3))

                ProgressCapsule(fraction: clampedFraction)
                    .fill(Color.accentColor)
            }
            .animation(.smooth, value: clampedFraction)
            .frame(height: 8)
        }
        .font(.footnote)
        .fontWeight(.bold)
    }
}

// MARK: - ActivityPageConfig

struct ActivityPageConfig {
    var label: String
    var stepsFraction: Double
    var kmFraction: Double
    var steps: Int
    var km: Double
    var goalSteps: Int
    var goalKm: Double
    var secondaryBar: (label: String, fraction: Double)?
}

// MARK: - WatchHomeView

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
                activityPage(ActivityPageConfig(
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
                hourlyPage
                    .navigationTitle("Hourly")

                // Page 3: This week
                activityPage(ActivityPageConfig(
                    label: "Week",
                    stepsFraction: weeklyStepsFraction,
                    kmFraction: weeklyKmFraction,
                    steps: store.weeklySteps,
                    km: store.weeklyKm,
                    goalSteps: Int(ProgressCalculator.stepGoal),
                    goalKm: ProgressCalculator.kmGoal
                ))

                // Page 4: Refresh
                refreshPage
            }
            .tabViewStyle(.verticalPage)
        }
    }

    @ViewBuilder
    private func activityPage(_ config: ActivityPageConfig) -> some View {
        VStack(spacing: 7) {
            ActivityRow(
                fraction: config.stepsFraction,
                systemImage: "figure.run",
                value: config.steps.formatted(),
                goal: "\(config.goalSteps.formatted()) steps"
            )

            ActivityRow(
                fraction: config.kmFraction,
                systemImage: "figure.outdoor.cycle",
                value: String(format: "%.1f", config.km),
                goal: String(format: "%.1f km", config.goalKm)
            )

            ArcProgressBar(fraction: config.stepsFraction + config.kmFraction) {
                HStack {
                    Text(config.label)
                    Spacer()
                    Text(String(format: "%.1f%%", (config.stepsFraction + config.kmFraction) * 100))
                }
            }

            if let secondary = config.secondaryBar {
                ArcProgressBar(fraction: secondary.fraction) {
                    HStack {
                        Text(secondary.label)
                        Spacer()
                        Text(String(format: "%.1f%%", secondary.fraction * 100))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var hourlyPage: some View {
        let maxUnits = store.hourlyActivity.map(\.units).max() ?? 0

        let minBar = maxUnits > 0 ? maxUnits * 0.04 : 0.01

        return VStack(spacing: 8) {
            Chart(store.hourlyActivity) { item in
                let displayValue = max(item.units, minBar)
                let hasActivity = item.units > 0
                BarMark(
                    x: .value("Hour", item.hour),
                    y: .value("Activity", displayValue),
                    width: .inset(2.5)
                )
                .clipShape(.capsule)
                .foregroundStyle(
                    hasActivity
                        ? Color.accentColor
                        : Color.secondary.opacity(0.25)
                )
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

        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var refreshPage: some View {
        Button("Refresh") {
            Task { await store.refreshFromHealthKit() }
        }
        .buttonStyle(.borderedProminent)
        .tint(.accentColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
