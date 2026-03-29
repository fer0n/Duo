import SwiftUI
import Charts

struct DailyChartView: View {
    @Environment(ChallengeStore.self) private var store

    private struct DayData: Identifiable {
        let id: Int
        let date: Date
        let stepsFraction: Double
        let kmFraction: Double
        let goalLine: Double
        let isToday: Bool
        let isFuture: Bool

        var total: Double { stepsFraction + kmFraction }
    }

    private struct ChartModel {
        let days: [DayData]
        let projSteps: Int
        let projKm: Double
        let hasFutureDays: Bool
        let goalChangePct: Double?
    }

    @State private var displayDays: [DayData] = []

    private var chartModel: ChartModel {
        let cal = Calendar.current
        let weekStart = cal.currentWeekStart(startingOn: store.settings.challengeStartWeekday)
        let todayStart = cal.startOfDay(for: .now)
        let todayIndex = max(0, min(
            cal.dateComponents([.day], from: weekStart, to: todayStart).day ?? 0, 6
        ))

        var byIndex: [Int: DailyEntry] = [:]
        for entry in store.currentWeekEntries {
            let diff = cal.dateComponents([.day], from: weekStart, to: cal.startOfDay(for: entry.date)).day ?? -1
            if (0..<7).contains(diff) { byIndex[diff] = entry }
        }

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
        let projectedFraction: Double = futureDaysCount > 0
            ? max(1.0 - progressThroughToday, 0.0) / Double(futureDaysCount)
            : 0.0
        let todayGoalFraction: Double = futureDaysCount > 0
            ? max(1.0 - progressBeforeToday, 0.0) / Double(futureDaysCount + 1)
            : 0.0
        let goalChangePct: Double? = todayGoalFraction > 0
            ? (projectedFraction - todayGoalFraction) / todayGoalFraction * 100
            : nil

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

        return ChartModel(
            days: days,
            projSteps: projSteps,
            projKm: projKm,
            hasFutureDays: futureDaysCount > 0,
            goalChangePct: goalChangePct
        )
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
        let minBarFraction = maxVal * 0.07

        VStack(spacing: 5) {
            Chart {
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
                        .frame(minWidth: 4, maxWidth: 8)
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
        .navigationTitle({
            if m.hasFutureDays, let pct = m.goalChangePct {
                "\(pct.formatted(.number.precision(.fractionLength(0)).sign(strategy: .always())))% / day"
            } else if m.hasFutureDays {
                "Left / day"
            } else {
                "Daily"
            }
        }())
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

#if os(watchOS)
#Preview {
    @Previewable @State var scenarioIndex = 0

    let store = ChallengeStore.preview(
        steps: ChallengeStore.previewScenarios[0].steps,
        km: ChallengeStore.previewScenarios[0].km
    )
    let todayKey = Date.todayKey()

    NavigationStack {
        TabView {
            DailyChartView()
        }
        .tabViewStyle(.verticalPage)
    }
    .environment(store)
    .task(id: scenarioIndex) {
        let s = ChallengeStore.previewScenarios[scenarioIndex]
        withAnimation(.smooth) {
            store.entries[todayKey] = DailyEntry(id: todayKey, steps: s.steps, cyclingKm: s.km, date: .now)
        }
    }
    .overlay(alignment: .top) {
        Button {
            scenarioIndex = (scenarioIndex + 1) % ChallengeStore.previewScenarios.count
        } label: {
            Text("\(scenarioIndex + 1)/\(ChallengeStore.previewScenarios.count)")
                .font(.system(size: 9, weight: .bold))
                .padding(4)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, -40)
        .padding(.bottom, 2)
    }
}
#endif
