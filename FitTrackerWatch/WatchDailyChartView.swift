import SwiftUI
import Charts

struct WatchDailyChartView: View {
    @Environment(ChallengeStore.self) private var store

    private struct DayData: Identifiable {
        let id: Int               // 0…6 within challenge week
        let date: Date            // midnight of this day
        let stepsFraction: Double // steps contribution to weekly goal
        let kmFraction: Double    // km contribution to weekly goal
        let goalLine: Double      // daily-goal fraction in effect for this day
        let isToday: Bool
        let isFuture: Bool

        var total: Double { stepsFraction + kmFraction }
    }

    private struct ChartModel {
        let days: [DayData]
        let projSteps: Int
        let projKm: Double
        let hasFutureDays: Bool
    }

    @State private var displayDays: [DayData] = []

    // All calculation lives here, out of body.
    private var chartModel: ChartModel {
        let cal = Calendar.current
        let weekStart = cal.currentWeekStart(startingOn: store.settings.challengeStartWeekday)
        let todayStart = cal.startOfDay(for: .now)
        let todayIndex = max(0, min(
            cal.dateComponents([.day], from: weekStart, to: todayStart).day ?? 0, 6
        ))

        // Map entries to their 0-based position within the challenge week.
        var byIndex: [Int: DailyEntry] = [:]
        for entry in store.currentWeekEntries {
            let diff = cal.dateComponents([.day], from: weekStart, to: cal.startOfDay(for: entry.date)).day ?? -1
            if (0..<7).contains(diff) { byIndex[diff] = entry }
        }

        // Progress accumulated before today (for the projected goal calculation).
        var progressBeforeToday = 0.0
        for i in 0..<todayIndex {
            if let e = byIndex[i] {
                progressBeforeToday += ProgressCalculator.weeklyProgressRaw(steps: e.steps, km: e.cyclingKm)
            }
        }
        let todayRaw = ProgressCalculator.weeklyProgressRaw(steps: store.todaySteps, km: store.todayKm)
        let progressThroughToday = progressBeforeToday + todayRaw

        let futureDaysCount = 7 - todayIndex - 1
        let (projSteps, projKm) = ProgressCalculator.dailyTarget(
            weeklyProgress: min(progressThroughToday, 1.0),
            remainingDays: futureDaysCount
        )
        // Goal fraction each future day would need (flat – "if no more progress today").
        let projectedFraction: Double = futureDaysCount > 0
            ? max(1.0 - progressThroughToday, 0.0) / Double(futureDaysCount)
            : 0.0

        var days: [DayData] = []
        var cumulative = 0.0

        for i in 0..<7 {
            let isFuture = i > todayIndex
            let isToday = i == todayIndex

            let stepsFraction: Double
            let kmFraction: Double
            if isFuture {
                stepsFraction = 0.0
                kmFraction = 0.0
            } else if let e = byIndex[i] {
                stepsFraction = Double(e.steps) / ProgressCalculator.stepGoal
                kmFraction = e.cyclingKm / ProgressCalculator.kmGoal
            } else {
                stepsFraction = 0.0
                kmFraction = 0.0
            }

            // For past/today days: the goal that was set at the start of that day.
            // For future days: the projected equal-share goal.
            let goalLine: Double = isFuture
                ? projectedFraction
                : max(1.0 - cumulative, 0.0) / Double(7 - i)

            let dayDate = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart

            days.append(DayData(
                id: i,
                date: dayDate,
                stepsFraction: stepsFraction,
                kmFraction: kmFraction,
                goalLine: goalLine,
                isToday: isToday,
                isFuture: isFuture
            ))

            if !isFuture { cumulative += stepsFraction + kmFraction }
        }

        return ChartModel(days: days, projSteps: projSteps, projKm: projKm, hasFutureDays: futureDaysCount > 0)
    }

    private func barDisplay(_ value: Double, min minFraction: Double) -> Double {
        value == 0 ? 0 : max(value, minFraction)
    }

    private func barGradient(value: Double, display: Double, color: Color) -> LinearGradient {
        let clearStop = display > 0 ? max(0.0, 1.0 - value / display) : 0.0
        return LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: clearStop),
                .init(color: color, location: clearStop),
                .init(color: color, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        let m = chartModel
        let maxVal = max(
            m.days.map(\.total).max() ?? 0,
            m.days.map(\.goalLine).max() ?? 0
        )
        // Minimum height so the capsule always renders rounded corners.
        let minBarFraction = maxVal * 0.07

        VStack(spacing: 5) {
            Chart {
                // Total bar (steps + km) in km color — drawn first, behind.
                ForEach(displayDays) { day in
                    let display = day.isFuture ? 0.0 : barDisplay(day.total, min: minBarFraction)
                    let color: Color = day.isFuture ? .secondary.opacity(0.15) : kmBarColor
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Total", display),
                        width: .fixed(14),
                        stacking: .unstacked
                    )
                    .clipShape(.capsule)
                    .foregroundStyle(barGradient(value: day.total, display: display, color: color))
                }

                // Steps-only bar in accent color — overlaid on top, shorter.
                ForEach(displayDays) { day in
                    let display = day.isFuture ? 0.0 : barDisplay(day.stepsFraction, min: minBarFraction)
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Steps", display),
                        width: .fixed(14),
                        stacking: .unstacked
                    )
                    .clipShape(.capsule)
                    .foregroundStyle(barGradient(value: day.stepsFraction, display: display, color: .accentColor))
                }

                // Dashed goal line: retroactive for past days, projected for future days.
                ForEach(displayDays) { day in
                    LineMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Goal", day.goalLine)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .foregroundStyle(.white.opacity(0.6))

                    PointMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Goal", day.goalLine)
                    )
                    .symbolSize(30)
                    .foregroundStyle(.white.opacity(0.9))
                }
            }
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...(maxVal > 0 ? maxVal * 1 : 0.02))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.weekday(.narrow))
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    Calendar.current.isDateInToday(date) ? Color.accentColor : Color.secondary
                                )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if m.hasFutureDays && (m.projSteps > 0 || m.projKm > 0) {
                HStack {
                    HStack(alignment: .center, spacing: 1) {
                        Image(systemName: "figure.run")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text("\(m.projSteps)")
                    }
                    Spacer()
                        .frame(minWidth: 5, maxWidth: 8)
                    HStack(alignment: .center, spacing: 1) {
                        Image(systemName: "figure.outdoor.cycle")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text(m.projKm.kmFormatted)
                    }
                }
                .font(.title3).monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fontWeight(.black)
                .fontWidth(.condensed)
            }
        }
        .navigationTitle(m.hasFutureDays ? "Left / day" : "Daily")
        .padding(.horizontal, 12)
        .onAppear {
            let days = m.days
            withAnimation(.smooth(duration: 1.0)) { displayDays = days }
        }
        .onChange(of: store.todaySteps) { _, _ in
            let days = chartModel.days
            withAnimation(.smooth(duration: 1.0)) { displayDays = days }
        }
    }
}

#Preview {
    NavigationStack {
        TabView {
            WatchDailyChartView()
        }
        .tabViewStyle(.verticalPage)
    }
    .environment(ChallengeStore.preview())
}
