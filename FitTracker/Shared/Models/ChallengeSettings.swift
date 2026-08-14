import Foundation

/// Storage shared between the app, the watch app and all widget extensions.
enum AppGroup {
    static let id = "group.net.octabits.FitTracker"

    /// Weekly goals live outside the settings blob so nonisolated widget code can read
    /// them without decoding JSON on every access.
    static let stepGoalKey = "goalSteps"
    static let kmGoalKey = "goalKm"

    static let entriesKey = "dailyEntries"
    static let settingsKey = "challengeSettings"
    static let hourlyKey = "hourlyActivity"
    /// Day the cached hourly data belongs to, so widgets don't show yesterday's hours.
    static let hourlyDayKey = "hourlyActivityDay"

    nonisolated(unsafe) static let defaults = UserDefaults(suiteName: id) ?? .standard
}

struct ChallengeSettings: Codable {
    // 1=Sunday, 2=Monday, ... 7=Saturday (matches Calendar.weekday)
    var challengeStartWeekday: Int = 2  // Monday default
    var notifyDailyGoal: Bool = false
    var notifyWeeklyGoal: Bool = false
    var dailyReminderEnabled: Bool = false
    var dailyReminderHour: Int = 20   // 8 PM default
    var dailyReminderMinute: Int = 0
    var stepGoal: Double = ProgressCalculator.defaultStepGoal
    var kmGoal: Double = ProgressCalculator.defaultKmGoal
}
