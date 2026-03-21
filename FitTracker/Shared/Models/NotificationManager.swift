import UserNotifications
import Foundation

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let defaults: UserDefaults
    private static let appGroupID = "group.com.pentlandFirth.FitTracker"
    private static let dailyNotifiedKey = "lastDailyGoalNotificationDay"
    private static let weeklyNotifiedKey = "lastWeeklyGoalNotificationWeekStart"
    private static let dailyReminderScheduledKey = "dailyReminderScheduledDay"
    private static let dailyReminderIdentifier = "dailyGoalReminder"

    private init() {
        self.defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
    }

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

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

    func markWeeklyGoalSeen(weekStartKey: String) {
        defaults.set(weekStartKey, forKey: Self.weeklyNotifiedKey)
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

    func scheduleDailyReminderIfNeeded(
        hour: Int,
        minute: Int,
        missingPercent: Int,
        missingSteps: Int,
        missingKm: Double
    ) async {
        let todayKey = Date.todayKey()
        guard defaults.string(forKey: Self.dailyReminderScheduledKey) != todayKey else { return }
        guard await isAuthorized() else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        guard let reminderDate = Calendar.current.date(from: components), reminderDate > .now else { return }

        defaults.set(todayKey, forKey: Self.dailyReminderScheduledKey)

        let kmFormatted = String(format: "%.1f", missingKm)
        let content = UNMutableNotificationContent()
        content.title = "Daily Goal: \(missingPercent)% to Go"
        content.body = "That's \(missingSteps.formatted()) steps or \(kmFormatted) km"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: hour, minute: minute),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.dailyReminderIdentifier]
        )
        defaults.removeObject(forKey: Self.dailyReminderScheduledKey)
    }

    private func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}
