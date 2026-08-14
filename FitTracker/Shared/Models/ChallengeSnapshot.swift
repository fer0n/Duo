import Foundation

/// Read-only view of the shared challenge data.
/// Built straight from the app group so widget extensions can render without
/// touching the `@MainActor` `ChallengeStore` or HealthKit.
struct ChallengeSnapshot {
    let settings: ChallengeSettings
    /// Entries of the current challenge week.
    let weekEntries: [DailyEntry]
    let weeklySteps: Int
    let weeklyKm: Double
    let todaySteps: Int
    let todayKm: Double
    let hourly: [HourlyActivity]

    init(defaults: UserDefaults = AppGroup.defaults) {
        let settings: ChallengeSettings
        if let data = defaults.data(forKey: AppGroup.settingsKey),
           let decoded = try? JSONDecoder().decode(ChallengeSettings.self, from: data) {
            settings = decoded
        } else {
            settings = ChallengeSettings()
        }
        self.settings = settings

        if let data = defaults.data(forKey: AppGroup.entriesKey),
           let entries = try? JSONDecoder().decode([String: DailyEntry].self, from: data) {
            let weekStart = Calendar.current.currentWeekStart(startingOn: settings.challengeStartWeekday)
            weekEntries = entries.values.filter { $0.date >= weekStart }
            weeklySteps = weekEntries.reduce(0) { $0 + $1.steps }
            weeklyKm = weekEntries.reduce(0.0) { $0 + $1.cyclingKm }
            let todayEntry = entries[Date.todayKey()]
            todaySteps = todayEntry?.steps ?? 0
            todayKm = todayEntry?.cyclingKm ?? 0.0
        } else {
            weekEntries = []
            weeklySteps = 0
            weeklyKm = 0
            todaySteps = 0
            todayKm = 0.0
        }

        // Only use the hourly cache when it was written today.
        if defaults.string(forKey: AppGroup.hourlyDayKey) == Date.todayKey(),
           let data = defaults.data(forKey: AppGroup.hourlyKey),
           let decoded = try? JSONDecoder().decode([HourlyActivity].self, from: data) {
            hourly = decoded
        } else {
            hourly = []
        }
    }

    // MARK: - Derived values

    var remainingDays: Int {
        Calendar.current.remainingDaysInChallengeWeek(startingOn: settings.challengeStartWeekday)
    }

    var weeklyProgress: Double {
        ProgressCalculator.weeklyProgress(steps: weeklySteps, km: weeklyKm)
    }

    var weeklyProgressRaw: Double {
        ProgressCalculator.weeklyProgressRaw(steps: weeklySteps, km: weeklyKm)
    }

    var weeklyStepsFraction: Double { ProgressCalculator.stepsFraction(weeklySteps) }
    var weeklyKmFraction: Double { ProgressCalculator.kmFraction(weeklyKm) }

    /// Daily target based on progress *before* today, so it stays stable throughout the day.
    var dailyTarget: (steps: Int, km: Double) {
        let prevProgress = ProgressCalculator.weeklyProgress(
            steps: weeklySteps - todaySteps,
            km: weeklyKm - todayKm
        )
        return ProgressCalculator.dailyTarget(weeklyProgress: prevProgress, remainingDays: remainingDays)
    }
}
