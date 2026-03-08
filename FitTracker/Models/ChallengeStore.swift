import Foundation
import Observation
import WidgetKit

@Observable
@MainActor
final class ChallengeStore {
    static let appGroupID = "group.com.pentlandFirth.FitTracker"
    private static let entriesKey = "dailyEntries"
    private static let settingsKey = "challengeSettings"

    private let defaults: UserDefaults

    var entries: [String: DailyEntry] = [:]
    var settings = ChallengeSettings()

    init() {
        self.defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        load()
    }

    // MARK: - Persistence

    private func load() {
        if let data = defaults.data(forKey: Self.entriesKey),
           let decoded = try? JSONDecoder().decode([String: DailyEntry].self, from: data) {
            entries = decoded
        }
        if let data = defaults.data(forKey: Self.settingsKey),
           let decoded = try? JSONDecoder().decode(ChallengeSettings.self, from: data) {
            settings = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.entriesKey)
        }
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.settingsKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
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

    // MARK: - Entry Management

    func todayEntry() -> DailyEntry {
        let key = Date.todayKey()
        return entries[key] ?? DailyEntry(
            id: key,
            steps: 0,
            cyclingKm: 0,
            date: Calendar.current.startOfDay(for: .now)
        )
    }

    func updateTodayEntry(steps: Int, km: Double) {
        var entry = todayEntry()
        entry.steps = steps
        entry.cyclingKm = km
        entries[entry.id] = entry
        save()
    }
}
