import UserNotifications
import Foundation

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let defaults: UserDefaults
    private static let appGroupID = "group.com.pentlandFirth.FitTracker"
    private static let dailyNotifiedKey = "lastDailyGoalNotificationDay"
    private static let weeklyNotifiedKey = "lastWeeklyGoalNotificationWeekStart"

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

    private func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}
