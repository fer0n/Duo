import Foundation
import Observation
import WidgetKit

struct HourlyActivity: Identifiable {
    let hour: Int
    let steps: Int
    let km: Double
    var id: Int { hour }
    var units: Double { ProgressCalculator.weeklyProgressRaw(steps: steps, km: km) }
}

@Observable
@MainActor
final class ChallengeStore {
    static let appGroupID = "group.com.pentlandFirth.FitTracker"
    private static let entriesKey = "dailyEntries"
    private static let settingsKey = "challengeSettings"

    private let defaults: UserDefaults
    private let healthKit = HealthKitManager.shared

    var entries: [String: DailyEntry] = [:]
    var settings = ChallengeSettings()
    var hourlyActivity: [HourlyActivity] = []

    init(skipHealthKit: Bool = false) {
        self.defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        loadFromDefaults()
        if !skipHealthKit {
            Task { await setupHealthKit() }
        }
    }

    // MARK: - HealthKit

    private func setupHealthKit() async {
        try? await healthKit.requestAuthorization()
        healthKit.enableBackgroundDelivery()
        healthKit.startObserving { [weak self] completionHandler in
            Task { @MainActor [weak self] in
                await self?.refreshFromHealthKit()
                completionHandler()
            }
        }
        await refreshFromHealthKit()
    }

    func refreshFromHealthKit() async {
        let weekStart = Calendar.current.currentWeekStart(startingOn: settings.challengeStartWeekday)
        async let weeklyData = healthKit.fetchWeeklyEntries(from: weekStart)
        async let hourlyData = healthKit.fetchTodayHourlyData()
        entries = await weeklyData
        hourlyActivity = (await hourlyData).map { HourlyActivity(hour: $0.hour, steps: $0.steps, km: $0.km) }
        writeEntriesToDefaults()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Persistence

    private func loadFromDefaults() {
        if let data = defaults.data(forKey: Self.entriesKey),
           let decoded = try? JSONDecoder().decode([String: DailyEntry].self, from: data) {
            entries = decoded
        }
        if let data = defaults.data(forKey: Self.settingsKey),
           let decoded = try? JSONDecoder().decode(ChallengeSettings.self, from: data) {
            settings = decoded
        }
    }

    /// Call after changing `settings` to persist and re-sync data.
    func save() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.settingsKey)
        }
        Task { await refreshFromHealthKit() }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func writeEntriesToDefaults() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.entriesKey)
        }
    }

    // MARK: - Weekly Data

    func currentWeekEntries() -> [DailyEntry] {
        let weekStart = Calendar.current.currentWeekStart(startingOn: settings.challengeStartWeekday)
        return entries.values.filter { $0.date >= weekStart }
    }

    var weeklySteps: Int {
        currentWeekEntries().reduce(0) { $0 + $1.steps }
    }

    var weeklyKm: Double {
        currentWeekEntries().reduce(0.0) { $0 + $1.cyclingKm }
    }

    var weeklyProgress: Double {
        ProgressCalculator.weeklyProgress(steps: weeklySteps, km: weeklyKm)
    }

    var weeklyStepsFraction: Double { Double(weeklySteps) / ProgressCalculator.stepGoal }
    var weeklyKmFraction: Double { weeklyKm / ProgressCalculator.kmGoal }

    var remainingDays: Int {
        Calendar.current.remainingDaysInChallengeWeek(startingOn: settings.challengeStartWeekday)
    }

    var todayEntry: DailyEntry? { entries[Date.todayKey()] }
    var todaySteps: Int { todayEntry?.steps ?? 0 }
    var todayKm: Double { todayEntry?.cyclingKm ?? 0.0 }

    var dailyGoal: (steps: Int, km: Double) {
        let prev = currentWeekEntries().filter { !Calendar.current.isDateInToday($0.date) }
        let prevProgress = ProgressCalculator.weeklyProgress(
            steps: prev.reduce(0) { $0 + $1.steps },
            km: prev.reduce(0.0) { $0 + $1.cyclingKm }
        )
        return ProgressCalculator.dailyTarget(weeklyProgress: prevProgress, remainingDays: remainingDays)
    }

    var dailyStepsFraction: Double {
        guard dailyGoal.steps > 0 else { return 0 }
        return Double(todaySteps) / Double(dailyGoal.steps)
    }

    var dailyKmFraction: Double {
        guard dailyGoal.km > 0 else { return 0 }
        return todayKm / dailyGoal.km
    }
}
