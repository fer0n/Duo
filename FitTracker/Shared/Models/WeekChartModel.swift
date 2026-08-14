import Foundation

/// One day of the challenge week as rendered by the weekly bar chart.
struct WeekDay: Identifiable, Equatable {
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

/// Everything the weekly chart needs, derived from the week's entries.
/// Nonisolated so widgets can build it from a `ChallengeSnapshot`.
struct WeekChartModel {
    let days: [WeekDay]
    /// Per-day target for the remaining days, given today's progress.
    let projSteps: Int
    let projKm: Double
    /// How that target shifted compared to what today's target was this morning.
    let deltaSteps: Int
    let deltaKm: Double
    let hasFutureDays: Bool
    /// "±X% / day", "Left / day" or "Daily" — how the remaining daily effort changed.
    let headerLabel: String

    init(weekEntries: [DailyEntry], startWeekday: Int, todaySteps: Int, todayKm: Double) {
        let cal = Calendar.current
        let weekStart = cal.currentWeekStart(startingOn: startWeekday)
        let todayStart = cal.startOfDay(for: .now)
        let todayIndex = max(0, min(
            cal.dateComponents([.day], from: weekStart, to: todayStart).day ?? 0, 6
        ))

        var byIndex: [Int: DailyEntry] = [:]
        for entry in weekEntries {
            let diff = cal.dateComponents([.day], from: weekStart, to: cal.startOfDay(for: entry.date)).day ?? -1
            if (0..<7).contains(diff) { byIndex[diff] = entry }
        }

        var progressBeforeToday = 0.0
        for i in 0..<todayIndex {
            if let e = byIndex[i] {
                progressBeforeToday += ProgressCalculator.weeklyProgressRaw(steps: e.steps, km: e.cyclingKm)
            }
        }
        let todayRaw = ProgressCalculator.weeklyProgressRaw(steps: todaySteps, km: todayKm)
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

        var days: [WeekDay] = []
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

            days.append(WeekDay(
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

        self.days = days
        self.projSteps = projSteps
        self.projKm = projKm
        self.deltaSteps = projSteps - todayGoalSteps
        self.deltaKm = projKm - todayGoalKm
        self.hasFutureDays = futureDaysCount > 0

        let todayGoalFraction = max(1.0 - progressBeforeToday, 0.0) / Double(futureDaysCount + 1)
        if futureDaysCount == 0 {
            headerLabel = "Daily"
        } else if todayGoalFraction <= 0 {
            headerLabel = "Left / day"
        } else {
            let pct = (projectedFraction - todayGoalFraction) / todayGoalFraction * 100
            headerLabel = "\(pct.formatted(.number.precision(.fractionLength(0)).sign(strategy: .always())))% / day"
        }
    }

    init(snapshot: ChallengeSnapshot) {
        self.init(
            weekEntries: snapshot.weekEntries,
            startWeekday: snapshot.settings.challengeStartWeekday,
            todaySteps: snapshot.todaySteps,
            todayKm: snapshot.todayKm
        )
    }
}
