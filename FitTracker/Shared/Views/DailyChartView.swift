import SwiftUI
import Charts

struct DailyChartView: View {
    @Environment(ChallengeStore.self) private var store

    /// Optional binding so a host (e.g. iOS `HomeView`) can render the adaptive header itself.
    var headerLabel: Binding<String>?

    private struct DayData: Identifiable {
        let id: Int
        let date: Date
        let stepsFraction: Double
        let kmFraction: Double
        let goalLine: Double
        let steps: Int
        let km: Double
        let goalSteps: Int
        let goalKm: Double
        let isToday: Bool
        let isFuture: Bool
        let isNextDay: Bool

        var total: Double { stepsFraction + kmFraction }
    }

    private struct ChartModel {
        let days: [DayData]
        let projSteps: Int
        let projKm: Double
        let deltaSteps: Int
        let deltaKm: Double
        let hasFutureDays: Bool
    }

    @State private var displayDays: [DayData] = []
    @State private var selectedDate: Date?

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
        let (todayGoalSteps, todayGoalKm) = ProgressCalculator.dailyTarget(
            weeklyProgress: min(progressBeforeToday, 1.0),
            remainingDays: futureDaysCount + 1
        )
        let projectedFraction: Double = futureDaysCount > 0
            ? max(1.0 - progressThroughToday, 0.0) / Double(futureDaysCount)
            : 0.0

        var days: [DayData] = []
        var cumulative = 0.0

        for i in 0..<7 {
            let isFuture = i > todayIndex
            let isToday = i == todayIndex

            let entry = isFuture ? nil : byIndex[i]
            let steps = entry?.steps ?? 0
            let km = entry?.cyclingKm ?? 0.0
            let stepsFraction = ProgressCalculator.stepsFraction(steps)
            let kmFraction = ProgressCalculator.kmFraction(km)

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
                steps: steps,
                km: km,
                goalSteps: Int((goalLine * ProgressCalculator.stepGoal).rounded()),
                goalKm: (goalLine * ProgressCalculator.kmGoal * 10).rounded() / 10,
                isToday: isToday,
                isFuture: isFuture,
                isNextDay: i == todayIndex + 1
            ))

            if !isFuture { cumulative += stepsFraction + kmFraction }
        }

        return ChartModel(
            days: days,
            projSteps: projSteps,
            projKm: projKm,
            deltaSteps: projSteps - todayGoalSteps,
            deltaKm: projKm - todayGoalKm,
            hasFutureDays: futureDaysCount > 0
        )
    }

    /// Matches the background behind the chart so the highlight marker can paint over the goal line.
    private var chartMaskColor: Color {
        #if os(watchOS)
        .black
        #else
        Color(.secondarySystemBackground)
        #endif
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

    /// A day is dimmed to grayscale when another day is the active one.
    private func isDimmed(_ day: DayData, activeDate: Date?) -> Bool {
        guard let activeDate else { return false }
        return !Calendar.current.isDate(day.date, inSameDayAs: activeDate)
    }

    private func day(for date: Date?, in days: [DayData]) -> DayData? {
        guard let date else { return nil }
        return days.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// Header text for the selected day's perspective, or the default projection label.
    private func headerText(selected: DayData?) -> String {
        guard let day = selected else { return store.dailyChartLabel }
        guard day.goalLine > 0 else { return "Daily" }
        let pct = day.total / day.goalLine * 100
        return "\(pct.formatted(.number.precision(.fractionLength(0))))%"
    }

    var body: some View {
        let m = chartModel
        // When no future days remain, fall back to the last day's perspective so the
        // chart never shows an empty footer.
        let activeDate: Date? = selectedDate ?? (m.hasFutureDays ? nil : displayDays.last?.date)
        let selected = day(for: activeDate, in: displayDays)
        let header = headerText(selected: selected)
        let maxVal = max(
            m.days.map(\.total).max() ?? 0,
            m.days.map(\.goalLine).max() ?? 0
        )
        let minBarFraction = maxVal * 0.07

        VStack(spacing: 5) {
            Chart {
                ForEach(displayDays) { day in
                    let display = day.isFuture ? 0.0 : barDisplay(day.total, min: minBarFraction)
                    let dimmed = isDimmed(day, activeDate: activeDate)
                    let color: Color = dimmed
                        ? .secondary.opacity(0.35)
                        : (day.isFuture ? .secondary.opacity(0.15) : kmBarColor)
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
                    let color: Color = isDimmed(day, activeDate: activeDate) ? .secondary.opacity(0.7) : .accentColor
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Steps", display),
                        width: .fixed(14),
                        stacking: .unstacked
                    )
                    .clipShape(.capsule)
                    .foregroundStyle(barGradient(value: day.stepsFraction, display: display, color: color))
                }

                ForEach(displayDays) { day in
                    let isNextDayHighlight = selected == nil && m.hasFutureDays && day.isNextDay

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
                    .foregroundStyle(
                        isNextDayHighlight ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.white.opacity(0.9))
                    )
                    .annotation(position: .overlay) {
                        if isNextDayHighlight {
                            ZStack {
                                // Paints over the dashed goal line so it never shows
                                // through the gap between the inner dot and the ring.
                                Circle()
                                    .fill(chartMaskColor)
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 5, height: 5)
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 1.5)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
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
            .chartXSelection(value: $selectedDate)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 2)

            if let day = selected {
                HStack(spacing: 0) {
                    WatchStatView(
                        systemImage: "figure.run",
                        value: day.steps.formatted(),
                        goal: day.goalSteps.formatted()
                    )
                    Spacer()
                        .frame(minWidth: 5, maxWidth: 8)
                    WatchStatView(
                        systemImage: "figure.outdoor.cycle",
                        value: day.km.kmFormatted,
                        goal: day.goalKm.kmFormatted
                    )
                }
                .fontWidth(.condensed)
            } else if m.hasFutureDays && (m.projSteps > 0 || m.projKm > 0) {
                HStack(spacing: 0) {
                    WatchStatView(
                        systemImage: "figure.run",
                        value: m.projSteps.formatted(),
                        goal: m.deltaSteps.formatted(.number.sign(strategy: .always()))
                    )
                    Spacer()
                        .frame(minWidth: 5, maxWidth: 8)
                    WatchStatView(
                        systemImage: "figure.outdoor.cycle",
                        value: m.projKm.kmFormatted,
                        goal: m.deltaKm.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always()))
                    )
                }
                .fontWidth(.condensed)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { selectedDate = nil }  // tap outside the bars clears the selection
        #if os(watchOS)
        .navigationTitle(header)
        #endif
        .onChange(of: header, initial: true) { _, new in
            headerLabel?.wrappedValue = new
        }
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
