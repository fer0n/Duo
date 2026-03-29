import UserNotifications
import Foundation
#if os(iOS)
import BackgroundTasks
#endif

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let defaults: UserDefaults
    private static let appGroupID = "group.com.pentlandFirth.FitTracker"
    private static let dailyNotifiedKey = "lastDailyGoalNotificationDay"
    private static let weeklyNotifiedKey = "lastWeeklyGoalNotificationWeekStart"
    private static let dailyReminderIdentifier = "dailyGoalReminder"
    private static let reminderHandledKey = "dailyReminderHandledDay"

    // Must be listed in Info.plist under BGTaskSchedulerPermittedIdentifiers.
    #if os(iOS)
    static let dailyReminderTaskIdentifier = "com.pentlandFirth.FitTracker.dailyGoalReminder"
    #endif

    private init() {
        self.defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
    }

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    // MARK: - Daily goal reached

    func sendDailyGoalNotificationIfNeeded() async {
        let todayKey = Date.todayKey()
        guard defaults.string(forKey: Self.dailyNotifiedKey) != todayKey else { return }
        guard await isAuthorized() else { return }
        defaults.set(todayKey, forKey: Self.dailyNotifiedKey)

        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Reached!"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "dailyGoal-\(todayKey)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    func clearDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func markDailyGoalSeen() {
        defaults.set(Date.todayKey(), forKey: Self.dailyNotifiedKey)
    }

    // MARK: - Weekly goal reached

    func markWeeklyGoalSeen(weekStartKey: String) {
        defaults.set(weekStartKey, forKey: Self.weeklyNotifiedKey)
    }

    func isWeeklyGoalMarkedDone(weekKey: String) -> Bool {
        defaults.string(forKey: Self.weeklyNotifiedKey) == weekKey
    }

    func sendWeeklyGoalNotificationIfNeeded(weekStartKey: String) async {
        guard defaults.string(forKey: Self.weeklyNotifiedKey) != weekStartKey else { return }
        guard await isAuthorized() else { return }
        defaults.set(weekStartKey, forKey: Self.weeklyNotifiedKey)

        let content = UNMutableNotificationContent()
        content.title = "Weekly Goal Reached!"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "weeklyGoal-\(weekStartKey)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Daily reminder

    /// Schedules a background task to fire accurate content just before the reminder
    /// deadline, plus a fallback notification at exactly the reminder time in case
    /// the background task doesn't run in time.
    func scheduleDailyReminder(hour: Int, minute: Int) async {
        guard !isReminderHandledToday() else { return }
        guard await isAuthorized() else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        guard let reminderDate = Calendar.current.date(from: components), reminderDate > .now else { return }

        // Fallback: fires at reminder time if the background task doesn't run first.
        let content = UNMutableNotificationContent()
        content.title = "Daily Reminder"
        content.body = "Your weekly goal may not be complete yet."
        content.sound = .default
        let fallback = UNNotificationRequest(
            identifier: Self.dailyReminderIdentifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: hour, minute: minute),
                repeats: false
            )
        )
        try? await UNUserNotificationCenter.current().add(fallback)

        #if os(iOS)
        // Background task: aim to run 1 hour before deadline so we can replace the
        // fallback with accurate content. iOS may run it later; the fallback covers that.
        let bgRequest = BGAppRefreshTaskRequest(identifier: Self.dailyReminderTaskIdentifier)
        bgRequest.earliestBeginDate = max(reminderDate.addingTimeInterval(-3600), .now)
        try? BGTaskScheduler.shared.submit(bgRequest)
        #endif
    }

    /// Removes only the pending fallback notification (used from the background task
    /// handler once we're about to deliver the accurate notification).
    func cancelFallbackNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.dailyReminderIdentifier]
        )
    }

    /// Removes the fallback notification and cancels the background task.
    /// Call when the daily or weekly goal is reached during normal app operation.
    func cancelDailyReminder() {
        cancelFallbackNotification()
        #if os(iOS)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.dailyReminderTaskIdentifier)
        #endif
    }

    /// Sends an immediate notification with the accurate remaining percentage.
    /// Called from the background task after fetching fresh HealthKit data.
    func sendAccurateDailyReminder(missingPercent: Int, missingSteps: Int, missingKm: Double) async {
        guard await isAuthorized() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Daily Goal: \(missingPercent)% to Go"
        content.body = "That's \(missingSteps.formatted()) steps or \(String(format: "%.1f", missingKm)) km"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: Self.dailyReminderIdentifier,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    func isReminderHandledToday() -> Bool {
        defaults.string(forKey: Self.reminderHandledKey) == Date.todayKey()
    }

    func markReminderHandled() {
        defaults.set(Date.todayKey(), forKey: Self.reminderHandledKey)
    }

    private func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}
