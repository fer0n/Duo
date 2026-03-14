import SwiftUI
import Charts

struct WatchWeeklyChartView: View {
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

    var body: some View {
        let m = chartModel
        let maxVal = max(
            m.days.map(\.total).max() ?? 0,
            m.days.map(\.goalLine).max() ?? 0
        )

        VStack(spacing: 8) {
            Chart {
                // Total bar (steps + km) in km color — drawn first, behind.
                ForEach(m.days) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Total", day.total),
                        width: .fixed(14),
                        stacking: .unstacked
                    )
                    .clipShape(.capsule)
                    .foregroundStyle(day.isFuture ? Color.secondary.opacity(0.15) : kmBarColor)
                }

                // Steps-only bar in accent color — overlaid on top, shorter.
                ForEach(m.days) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Steps", day.stepsFraction),
                        width: .fixed(14),
                        stacking: .unstacked
                    )
                    .clipShape(.capsule)
                    .foregroundStyle(day.isFuture ? Color.clear : Color.accentColor)
                }

                // Dashed goal line: retroactive for past days, projected for future days.
                ForEach(m.days) { day in
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
        .navigationTitle("Daily")
        .padding(.horizontal, 12)
    }
}

#Preview {
    let store = ChallengeStore(skipHealthKit: true)
    let cal = Calendar.current
    let weekStart = cal.currentWeekStart(startingOn: store.settings.challengeStartWeekday)
    let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    // Fill past days + today with sample data (all entries have both steps and km).
    let todayStart = cal.startOfDay(for: .now)
    let todayIndex = max(0, min(
        cal.dateComponents([.day], from: weekStart, to: todayStart).day ?? 0, 6
    ))
    let samples: [(steps: Int, km: Double)] = [
        (9_000, 5.0), (7_500, 3.5), (11_000, 2.0),
        (4_200, 4.5), (8_000, 6.0), (6_000, 2.5), (5_000, 3.0)
    ]
    for i in 0...todayIndex {
        let date = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
        let key = fmt.string(from: date)
        store.entries[key] = DailyEntry(id: key, steps: samples[i].steps, cyclingKm: samples[i].km, date: date)
    }

    return WatchWeeklyChartView()
        .environment(store)
}
