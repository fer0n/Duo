import UserNotifications
import Foundation
#if os(iOS)
import BackgroundTasks
#endif

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let defaults: UserDefaults
    private static let appGroupID = "group.net.octabits.FitTracker"
    private static let dailyNotifiedKey = "lastDailyGoalNotificationDay"
    private static let weeklyNotifiedKey = "lastWeeklyGoalNotificationWeekStart"
    private static let dailyReminderIdentifier = "dailyGoalReminder"

    // Must be listed in Info.plist under BGTaskSchedulerPermittedIdentifiers.
    #if os(iOS)
    static let dailyReminderTaskIdentifier = "net.octabits.FitTracker.dailyGoalReminder"
    /// How long before the reminder fires the background task should try to refresh it.
    private static let reminderRefreshLeadTime: TimeInterval = 30 * 60
    #endif

    private override init() {
        self.defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        super.init()
    }

    /// Call once at launch so goal notifications are also shown while the app is open —
    /// without a delegate iOS silently drops them in the foreground.
    func becomeNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    /// True once the user has explicitly declined — used to explain why nothing arrives.
    func isDenied() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings()
            .authorizationStatus == .denied
    }

    // MARK: - Daily goal reached

    func sendDailyGoalNotificationIfNeeded() async {
        let todayKey = Date.todayKey()
        guard defaults.string(forKey: Self.dailyNotifiedKey) != todayKey else { return }
        guard await isAuthorized() else { return }
        defaults.set(todayKey, forKey: Self.dailyNotifiedKey)

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Daily Goal Reached!")
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
        content.title = String(localized: "Weekly Goal Reached!")
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "weeklyGoal-\(weekStartKey)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Daily reminder

    #if os(iOS)
    /// (Re)schedules today's "goal not reached" reminder for the user's chosen time.
    ///
    /// Safe to call as often as progress changes: adding a request with the same
    /// identifier replaces the pending one, so the notification always carries the
    /// latest numbers and is never delivered before its time. `cancelDailyReminder()`
    /// removes it as soon as the goal is reached.
    ///
    /// A background refresh is queued for shortly before the reminder as a backstop for
    /// the case where no HealthKit update arrives in the final stretch of the day.
    func scheduleDailyReminder(
        hour: Int,
        minute: Int,
        missingPercent: Int,
        missingSteps: Int,
        missingKm: Double
    ) async {
        guard await isAuthorized() else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        guard let reminderDate = Calendar.current.date(from: components), reminderDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Daily Goal: \(missingPercent)% to Go")
        content.body = Self.reminderBody(steps: missingSteps, km: missingKm)
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: Self.dailyReminderIdentifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.hour, .minute], from: reminderDate),
                repeats: false
            )
        )
        try? await UNUserNotificationCenter.current().add(request)

        scheduleReminderRefresh(before: reminderDate)
    }

    /// "That's 4,200 steps or 2.8 km" — drops whichever activity is switched off.
    private static func reminderBody(steps: Int, km: Double) -> String {
        switch (steps > 0, km > 0) {
        case (true, true): String(localized: "That's \(steps.formatted()) steps or \(km.kmFormatted) km")
        case (true, false): String(localized: "That's \(steps.formatted()) steps to go")
        case (false, true): String(localized: "That's \(km.kmFormatted) km to go")
        case (false, false): String(localized: "Almost there")
        }
    }

    private func scheduleReminderRefresh(before reminderDate: Date) {
        let earliestBeginDate = reminderDate.addingTimeInterval(-Self.reminderRefreshLeadTime)
        guard earliestBeginDate > .now else { return }
        let request = BGAppRefreshTaskRequest(identifier: Self.dailyReminderTaskIdentifier)
        request.earliestBeginDate = earliestBeginDate
        try? BGTaskScheduler.shared.submit(request)
    }
    #endif

    /// Removes the pending reminder and its background refresh. Call when the daily or
    /// weekly goal is reached, or when the reminder is switched off.
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.dailyReminderIdentifier]
        )
        #if os(iOS)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.dailyReminderTaskIdentifier)
        #endif
    }

    private func isAuthorized() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings()
            .authorizationStatus
        return status == .authorized || status == .provisional
    }
}
