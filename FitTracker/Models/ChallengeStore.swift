import Foundation
import Observation
import WidgetKit
import SwiftUI

struct WeeklyStats {
    let entries: [DailyEntry]
    let steps: Int
    let km: Double
    let stepsFraction: Double
    let kmFraction: Double
    let progress: Double
}

struct HourlyActivity: Identifiable {
    let hour: Int
    let steps: Int
    let km: Double
    var id: Int { hour }
    var date: Date { Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now }
    var units: Double { ProgressCalculator.weeklyProgressRaw(steps: steps, km: km) }
}

@Observable
@MainActor
final class ChallengeStore {
    static let appGroupID = "group.com.pentlandFirth.FitTracker"
    private static let entriesKey = "dailyEntries"
    private static let settingsKey = "challengeSettings"
    private static let previousSessionKey = "previousSessionEntries"

    private let defaults: UserDefaults
    private let healthKit = HealthKitManager.shared

    var entries: [String: DailyEntry] = [:]
    var settings = ChallengeSettings()
    var hourlyActivity: [HourlyActivity] = []

    @ObservationIgnored private var hasUnsavedSnapshot = false
    @ObservationIgnored private var isInitialRefresh = true

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
        let (newEntries, newHourly) = await (weeklyData, hourlyData)
        let todayKey = Date.todayKey()
        var merged = newEntries
        if merged[todayKey] == nil { merged[todayKey] = entries[todayKey] }
        let newHourlyActivity = newHourly.map { HourlyActivity(hour: $0.hour, steps: $0.steps, km: $0.km) }
        let isFirst = isInitialRefresh
        isInitialRefresh = false
        let entriesChanged = merged != entries
        let animation: Animation = isFirst
            ? .smooth(duration: 1.5).delay(2)
            : .smooth(duration: 1.5)
        if isFirst { entries = [:] }   // reset to zero so the reveal animation always plays
        withAnimation(animation) {
            if entriesChanged || isFirst { entries = merged }
            hourlyActivity = newHourlyActivity
        }
        guard entriesChanged || isFirst else { return }
        defaults.removeObject(forKey: Self.previousSessionKey)
        hasUnsavedSnapshot = true
        writeEntriesToDefaults()
        WidgetCenter.shared.reloadAllTimelines()
        await checkGoalNotifications(weekStart: weekStart)
    }

    // MARK: - Notifications

    private func checkGoalNotifications(weekStart: Date) async {
        let notifier = NotificationManager.shared
        let weekly = weeklyStats
        let weeklyGoalReached = weekly.progress >= 1.0

        if settings.notifyWeeklyGoal && weeklyGoalReached {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let weekKey = formatter.string(from: weekStart)
            await notifier.sendWeeklyGoalNotificationIfNeeded(weekStartKey: weekKey)
        }

        if settings.notifyDailyGoal && !weeklyGoalReached {
            let goal = dailyGoal
            if goal.steps > 0 || goal.km > 0 {
                let stepsFraction = goal.steps > 0 ? Double(todaySteps) / Double(goal.steps) : 1.0
                let kmFraction = goal.km > 0 ? todayKm / goal.km : 1.0
                if stepsFraction + kmFraction >= 1.0 {
                    await notifier.sendDailyGoalNotificationIfNeeded()
                }
            }
        }
    }

    // MARK: - Persistence

    private func loadFromDefaults() {
        // Prefer previous session snapshot (what user last saw) so launch animates to current data.
        // Falls back to current cache on first launch or after first refresh clears the snapshot.
        let entriesData = defaults.data(forKey: Self.previousSessionKey)
            ?? defaults.data(forKey: Self.entriesKey)
        if let data = entriesData,
           let decoded = try? JSONDecoder().decode([String: DailyEntry].self, from: data) {
            entries = decoded
        }
        if let data = defaults.data(forKey: Self.settingsKey),
           let decoded = try? JSONDecoder().decode(ChallengeSettings.self, from: data) {
            settings = decoded
        }
    }

    func saveSessionSnapshot() {
        guard hasUnsavedSnapshot else { return }
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.previousSessionKey)
            hasUnsavedSnapshot = false
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

    var currentWeekEntries: [DailyEntry] {
        let weekStart = Calendar.current.currentWeekStart(startingOn: settings.challengeStartWeekday)
        return entries.values.filter { $0.date >= weekStart }
    }

    /// All weekly stats derived from a single pass over `currentWeekEntries`.
    /// Read this once per `body` render instead of accessing individual weekly properties separately.
    var weeklyStats: WeeklyStats {
        let week = currentWeekEntries
        let steps = week.reduce(0) { $0 + $1.steps }
        let km = week.reduce(0.0) { $0 + $1.cyclingKm }
        return WeeklyStats(
            entries: week,
            steps: steps,
            km: km,
            stepsFraction: Double(steps) / ProgressCalculator.stepGoal,
            kmFraction: km / ProgressCalculator.kmGoal,
            progress: ProgressCalculator.weeklyProgress(steps: steps, km: km)
        )
    }

    var remainingDays: Int {
        Calendar.current.remainingDaysInChallengeWeek(startingOn: settings.challengeStartWeekday)
    }

    var todayEntry: DailyEntry? { entries[Date.todayKey()] }
    var todaySteps: Int { todayEntry?.steps ?? 0 }
    var todayKm: Double { todayEntry?.cyclingKm ?? 0.0 }

    var dailyGoal: (steps: Int, km: Double) {
        let prev = currentWeekEntries.filter { !Calendar.current.isDateInToday($0.date) }
        let prevProgress = ProgressCalculator.weeklyProgress(
            steps: prev.reduce(0) { $0 + $1.steps },
            km: prev.reduce(0.0) { $0 + $1.cyclingKm }
        )
        return ProgressCalculator.dailyTarget(weeklyProgress: prevProgress, remainingDays: remainingDays)
    }

    /// Computes `dailyGoal` once and returns both fractions together with the goal values for display labels.
    /// Read this once per `body` render instead of accessing `dailyStepsFraction`/`dailyKmFraction` separately.
    var dailyContext: (stepsFraction: Double, kmFraction: Double, goalSteps: Int, goalKm: Double) {
        let goal = dailyGoal
        return (
            stepsFraction: goal.steps > 0 ? Double(todaySteps) / Double(goal.steps) : 0,
            kmFraction: goal.km > 0 ? todayKm / goal.km : 0,
            goalSteps: goal.steps,
            goalKm: goal.km
        )
    }
}
