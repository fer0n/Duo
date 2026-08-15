import Foundation
import Observation
import WidgetKit
import SwiftUI
#if os(iOS)
import BackgroundTasks
#endif

@Observable
@MainActor
final class ChallengeStore {
    static let appGroupID = AppGroup.id
    private static let entriesKey = AppGroup.entriesKey
    private static let settingsKey = AppGroup.settingsKey
    private static let previousSessionKey = "previousSessionEntries"

    private let defaults = AppGroup.defaults
    private let healthKit = HealthKitManager.shared

    var entries: [String: DailyEntry] = [:]
    var settings = ChallengeSettings()
    var hourlyActivity: [HourlyActivity] = []

    @ObservationIgnored private var hasUnsavedSnapshot = false
    @ObservationIgnored private var isInitialRefresh = true
    @ObservationIgnored let skipsHealthKit: Bool

    init(skipHealthKit: Bool = false) {
        self.skipsHealthKit = skipHealthKit
        loadFromDefaults()
        ProgressCalculator.storeGoals(steps: settings.stepGoal, km: settings.kmGoal)
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
        let hourlyChanged = newHourlyActivity != hourlyActivity
        let animation: Animation = isFirst
            ? .smooth(duration: 1.5).delay(2)
            : .smooth(duration: 1.5)
        withAnimation(animation) {
            if entriesChanged || isFirst { entries = merged }
            hourlyActivity = newHourlyActivity
        }
        if hourlyChanged { writeHourlyToDefaults() }
        if entriesChanged || isFirst {
            defaults.removeObject(forKey: Self.previousSessionKey)
            hasUnsavedSnapshot = true
            writeEntriesToDefaults()
        }
        guard entriesChanged || isFirst || hourlyChanged else { return }
        WidgetCenter.shared.reloadAllTimelines()
        guard entriesChanged || isFirst else { return }
        await checkGoalNotifications(weekStart: weekStart)
    }

    // MARK: - Notifications

    /// Combined daily progress (0…∞) and whether the daily goal is considered reached.
    /// A goal of 0 disables that activity, so it contributes nothing (see `ProgressCalculator`).
    private func dailyProgress(goal: (steps: Int, km: Double)) -> (combined: Double, reached: Bool) {
        let stepsFraction = goal.steps > 0 ? Double(todaySteps) / Double(goal.steps) : 0
        let kmFraction = goal.km > 0 ? todayKm / goal.km : 0
        let combined = stepsFraction + kmFraction
        return (combined, (goal.steps > 0 || goal.km > 0) && combined >= 1.0)
    }

    /// Brings pending notifications in line with the current data and settings.
    /// Call after anything that can change the outcome — settings edits included, since
    /// those leave the HealthKit data untouched and so don't trigger a refresh.
    func syncNotifications() async {
        let weekStart = Calendar.current.currentWeekStart(startingOn: settings.challengeStartWeekday)
        await checkGoalNotifications(weekStart: weekStart)
    }

    /// Notifications are owned by the iOS app only — the watch app shares this store and
    /// would otherwise schedule the same alerts a second time.
    private func checkGoalNotifications(weekStart: Date) async {
        #if os(iOS)
        let notifier = NotificationManager.shared
        let weekly = weeklyStats
        let weeklyGoalReached = weekly.progress >= 1.0

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekKey = formatter.string(from: weekStart)

        if weeklyGoalReached {
            if settings.notifyWeeklyGoal {
                await notifier.sendWeeklyGoalNotificationIfNeeded(weekStartKey: weekKey)
            } else {
                // Persist completion so stale HealthKit updates can't re-schedule the reminder.
                notifier.markWeeklyGoalSeen(weekStartKey: weekKey)
            }
        }

        // Use persisted state in addition to live data so that a stale HealthKit
        // background update (where weeklyProgress appears < 1.0) cannot re-schedule
        // the daily reminder after the weekly goal has already been reached.
        let weeklyDone = weeklyGoalReached || notifier.isWeeklyGoalMarkedDone(weekKey: weekKey)

        let goal = dailyGoal
        let (combinedProgress, dailyGoalReached) = dailyProgress(goal: goal)

        if settings.notifyDailyGoal && !weeklyDone && dailyGoalReached {
            await notifier.sendDailyGoalNotificationIfNeeded()
        }

        let hasGoal = goal.steps > 0 || goal.km > 0
        guard settings.dailyReminderEnabled, hasGoal, !dailyGoalReached, !weeklyDone else {
            notifier.cancelDailyReminder()
            return
        }

        // Re-scheduling replaces the pending reminder, so its numbers stay current
        // right up to the moment it fires.
        let missingFraction = max(0.0, 1.0 - combinedProgress)
        await notifier.scheduleDailyReminder(
            hour: settings.dailyReminderHour,
            minute: settings.dailyReminderMinute,
            missingPercent: Int((missingFraction * 100).rounded()),
            missingSteps: Int((missingFraction * Double(goal.steps)).rounded()),
            missingKm: missingFraction * goal.km
        )
        #endif
    }

    #if os(iOS)
    /// Called by the BGAppRefreshTask registered in FitTrackerApp, shortly before the
    /// reminder is due. Fetches fresh HealthKit data, then either cancels the pending
    /// reminder (goal reached in the meantime) or updates it with accurate numbers.
    func handleDailyReminderTask(_ task: BGAppRefreshTask) async {
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        await refreshFromHealthKit()  // updates entries + widgets
        await syncNotifications()     // …even if the data was unchanged
        task.setTaskCompleted(success: true)
    }
    #endif

    /// Call when the user opens the app and can see goal progress.
    /// Suppresses any pending notifications for goals that are already met.
    func markGoalsSeen() {
        let notifier = NotificationManager.shared
        let weekly = weeklyStats
        let weeklyGoalReached = weekly.progress >= 1.0

        if weeklyGoalReached {
            let weekStart = Calendar.current.currentWeekStart(startingOn: settings.challengeStartWeekday)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            notifier.markWeeklyGoalSeen(weekStartKey: formatter.string(from: weekStart))
        }

        if dailyProgress(goal: dailyGoal).reached {
            notifier.markDailyGoalSeen()
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
        ProgressCalculator.storeGoals(steps: settings.stepGoal, km: settings.kmGoal)
        Task {
            await refreshFromHealthKit()
            // Always re-sync: a settings change alone (new goal, new reminder time)
            // leaves the HealthKit data unchanged, so the refresh may skip the check.
            await syncNotifications()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func writeEntriesToDefaults() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.entriesKey)
        }
    }

    private func writeHourlyToDefaults() {
        if let data = try? JSONEncoder().encode(hourlyActivity) {
            defaults.set(data, forKey: AppGroup.hourlyKey)
            defaults.set(Date.todayKey(), forKey: AppGroup.hourlyDayKey)
        }
    }

    #if DEBUG
    /// Screenshot tooling: persists in-memory sample data to the app group so widgets
    /// (which read the app group directly, not this store) show the same demo data.
    func persistDemoSnapshotForWidgets() {
        writeEntriesToDefaults()
        writeHourlyToDefaults()
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.settingsKey)
        }
        ProgressCalculator.storeGoals(steps: settings.stepGoal, km: settings.kmGoal)
        WidgetCenter.shared.reloadAllTimelines()
    }
    #endif

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
            stepsFraction: ProgressCalculator.stepsFraction(steps),
            kmFraction: ProgressCalculator.kmFraction(km),
            progress: ProgressCalculator.weeklyProgress(steps: steps, km: km)
        )
    }

    var remainingDays: Int {
        Calendar.current.remainingDaysInChallengeWeek(startingOn: settings.challengeStartWeekday)
    }

    var todayEntry: DailyEntry? { entries[Date.todayKey()] }
    var todaySteps: Int { todayEntry?.steps ?? 0 }
    var todayKm: Double { todayEntry?.cyclingKm ?? 0.0 }

    /// Header label for the daily-chart section: "±X% / day", "Left / day", or "Daily".
    var dailyChartLabel: String {
        WeekChartModel(
            weekEntries: currentWeekEntries,
            startWeekday: settings.challengeStartWeekday,
            todaySteps: todaySteps,
            todayKm: todayKm
        ).headerLabel
    }

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
            stepsFraction: goal.steps > 0 ? Double(todaySteps) / Double(goal.steps) : 1,
            kmFraction: goal.km > 0 ? todayKm / goal.km : 1,
            goalSteps: goal.steps,
            goalKm: goal.km
        )
    }
}
