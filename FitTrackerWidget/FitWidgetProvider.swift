import WidgetKit

/// Everything the iOS widgets render, derived once per timeline refresh.
struct FitWidgetEntry: TimelineEntry {
    let date: Date

    // Today
    let dailyStepsFraction: Double
    let dailyKmFraction: Double
    let todaySteps: Int
    let todayKm: Double
    let dailyGoalSteps: Int
    let dailyGoalKm: Double
    let weeklyGoalReached: Bool

    // Week
    let weekDays: [WeekDay]
    let weekHeader: String
    let weeklySteps: Int
    let weeklyKm: Double
    let weeklyStepsFraction: Double
    let weeklyKmFraction: Double
    let weekGoalSteps: Int
    let weekGoalKm: Double

    // Today by hour
    let hourly: [HourlyActivity]

    // Small widget configuration
    var showStats: Bool = true

    init(date: Date, snapshot: ChallengeSnapshot) {
        let goal = snapshot.dailyTarget
        let chart = WeekChartModel(snapshot: snapshot)

        self.date = date
        dailyStepsFraction = goal.steps > 0 ? Double(snapshot.todaySteps) / Double(goal.steps) : 1
        dailyKmFraction = goal.km > 0 ? snapshot.todayKm / goal.km : 1
        todaySteps = snapshot.todaySteps
        todayKm = snapshot.todayKm
        dailyGoalSteps = goal.steps
        dailyGoalKm = goal.km
        weeklyGoalReached = snapshot.weeklyProgress >= 1.0

        weekDays = chart.days
        weekHeader = chart.headerLabel
        weeklySteps = snapshot.weeklySteps
        weeklyKm = snapshot.weeklyKm
        weeklyStepsFraction = snapshot.weeklyStepsFraction
        weeklyKmFraction = snapshot.weeklyKmFraction
        weekGoalSteps = Int(ProgressCalculator.stepGoal)
        weekGoalKm = ProgressCalculator.kmGoal

        hourly = snapshot.hourly
    }
}

struct FitWidgetProvider: TimelineProvider {
    typealias Entry = FitWidgetEntry

    func placeholder(in context: Context) -> FitWidgetEntry {
        WidgetSampleData.entry
    }

    func getSnapshot(in context: Context, completion: @escaping (FitWidgetEntry) -> Void) {
        let entry = context.isPreview
            ? WidgetSampleData.entry
            : FitWidgetEntry(date: .now, snapshot: ChallengeSnapshot())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FitWidgetEntry>) -> Void) {
        let entry = FitWidgetEntry(date: .now, snapshot: ChallengeSnapshot())
        // Refresh at the top of the next hour
        let nextUpdate = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date(timeIntervalSinceNow: 3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}
