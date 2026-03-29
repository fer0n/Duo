import Foundation
import Observation
import WidgetKit
import SwiftUI
#if os(iOS)
import BackgroundTasks
#endif

struct WeeklyStats {
    let entries: [DailyEntry]
    let steps: Int
    let km: Double
    let stepsFraction: Double
    let kmFraction: Double
    let progress: Double
}

struct HourlyActivity: Identifiable, Equatable {
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

    /// Combined daily progress (0…∞) and whether the daily goal is considered reached.
    private var dailyProgress: (combined: Double, reached: Bool) {
        let goal = dailyGoal
        let stepsFraction = goal.steps > 0 ? Double(todaySteps) / Double(goal.steps) : 1.0
        let kmFraction = goal.km > 0 ? todayKm / goal.km : 1.0
        let combined = stepsFraction + kmFraction
        return (combined, (goal.steps > 0 || goal.km > 0) && combined >= 1.0)
    }

    private func checkGoalNotifications(weekStart: Date) async {
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

        let (_, dailyGoalReached) = dailyProgress

        if settings.notifyDailyGoal && !weeklyDone && dailyGoalReached {
            await notifier.sendDailyGoalNotificationIfNeeded()
        }

        if settings.dailyReminderEnabled {
            if dailyGoalReached || weeklyDone {
                notifier.cancelDailyReminder()
            } else {
                await notifier.scheduleDailyReminder(
                    hour: settings.dailyReminderHour,
                    minute: settings.dailyReminderMinute
                )
            }
        }
    }

    #if os(iOS)
    /// Called by the BGAppRefreshTask registered in FitTrackerApp.
    /// Cancels the fallback notification, fetches fresh HealthKit data, then sends
    /// an accurate "X% to go" notification if the goal still isn't met.
    /// If the reminder deadline has already passed the fallback will have fired and
    /// we do nothing beyond updating the widget.
    func handleDailyReminderTask(_ task: BGAppRefreshTask) async {
        let notifier = NotificationManager.shared

        // Prevent checkGoalNotifications (called inside refreshFromHealthKit) from
        // rescheduling the reminder for today now that we are handling it.
        notifier.markReminderHandled()
        notifier.cancelFallbackNotification()

        task.expirationHandler = { task.setTaskCompleted(success: false) }

        // If we're past the reminder deadline the fallback has already fired.
        // Still refresh so widgets show the latest overshoot.
        let hour = settings.dailyReminderHour
        let minute = settings.dailyReminderMinute
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = hour
        comps.minute = minute
        let deadlinePassed = Calendar.current.date(from: comps).map { $0 <= .now } ?? false

        let weekStart = Calendar.current.currentWeekStart(startingOn: settings.challengeStartWeekday)
        await refreshFromHealthKit()  // updates entries + widgets; won't reschedule reminder

        if deadlinePassed {
            task.setTaskCompleted(success: true)
            return
        }

        // Check goals with the just-fetched data.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekKey = formatter.string(from: weekStart)
        let weeklyDone = weeklyStats.progress >= 1.0 || notifier.isWeeklyGoalMarkedDone(weekKey: weekKey)
        if weeklyDone {
            task.setTaskCompleted(success: true)
            return
        }

        let (combinedProgress, dailyGoalReached) = dailyProgress
        if dailyGoalReached {
            task.setTaskCompleted(success: true)
            return
        }

        let missingFraction = max(0.0, 1.0 - combinedProgress)
        let goal = dailyGoal
        await notifier.sendAccurateDailyReminder(
            missingPercent: Int((missingFraction * 100).rounded()),
            missingSteps: Int((missingFraction * Double(goal.steps)).rounded()),
            missingKm: missingFraction * goal.km
        )
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

        let goal = dailyGoal
        if goal.steps > 0 || goal.km > 0 {
            let stepsFraction = goal.steps > 0 ? Double(todaySteps) / Double(goal.steps) : 1.0
            let kmFraction = goal.km > 0 ? todayKm / goal.km : 1.0
            if stepsFraction + kmFraction >= 1.0 {
                notifier.markDailyGoalSeen()
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
        // Cancel any pending reminder so checkGoalNotifications can reschedule with updated settings.
        NotificationManager.shared.cancelDailyReminder()
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
