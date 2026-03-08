import Foundation

extension Calendar {
    // Midnight of the first day of the current challenge week
    func currentWeekStart(startingOn weekday: Int) -> Date {
        let today = startOfDay(for: .now)
        let todayWeekday = component(.weekday, from: today)
        let daysBack = (todayWeekday - weekday + 7) % 7
        return date(byAdding: .day, value: -daysBack, to: today) ?? today
    }

    // Days remaining in the challenge week including today (min 1)
    func remainingDaysInChallengeWeek(startingOn weekday: Int) -> Int {
        let weekStart = currentWeekStart(startingOn: weekday)
        let weekEnd = date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        let today = startOfDay(for: .now)
        let days = dateComponents([.day], from: today, to: weekEnd).day ?? 1
        return max(days, 1)
    }
}

extension Date {
    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }
}
