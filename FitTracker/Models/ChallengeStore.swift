import Foundation
import Observation
import WidgetKit

struct HourlyActivity: Identifiable {
    let hour: Int
    let steps: Int
    let km: Double
    var id: Int { hour }
    var units: Double {
        Double(steps) / ProgressCalculator.stepGoal + km / ProgressCalculator.kmGoal
    }
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
        healthKit.startObserving { [weak self] in
            Task { @MainActor [weak self] in
                await self?.refreshFromHealthKit()
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

    var remainingDays: Int {
        Calendar.current.remainingDaysInChallengeWeek(startingOn: settings.challengeStartWeekday)
    }
}
