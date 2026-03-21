import Foundation

struct ChallengeSettings: Codable {
    // 1=Sunday, 2=Monday, ... 7=Saturday (matches Calendar.weekday)
    var challengeStartWeekday: Int = 2  // Monday default
    var notifyDailyGoal: Bool = false
    var notifyWeeklyGoal: Bool = false
    var dailyReminderEnabled: Bool = false
    var dailyReminderHour: Int = 20   // 8 PM default
    var dailyReminderMinute: Int = 0
}
