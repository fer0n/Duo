import Foundation

/// Stand-in week for placeholders and previews, so neither touches real data.
enum WeekChartSampleData {
    static let todaySteps = 4_200
    static let todayKm = 2.6

    static var model: WeekChartModel {
        let cal = Calendar.current
        let startWeekday = ChallengeSettings().challengeStartWeekday
        let weekStart = cal.currentWeekStart(startingOn: startWeekday)
        let pastDays: [(steps: Int, km: Double)] = [
            (8_500, 1.3), (6_200, 1.3), (9_100, 0),
            (1_200, 0), (500, 1.0), (4_300, 6.0)
        ]
        let todayIndex = max(0, min(
            cal.dateComponents([.day], from: weekStart, to: cal.startOfDay(for: .now)).day ?? 0, 6
        ))

        var entries: [DailyEntry] = (0..<todayIndex).map { i in
            let date = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
            let day = pastDays[i % pastDays.count]
            return DailyEntry(id: "sample-\(i)", steps: day.steps, cyclingKm: day.km, date: date)
        }
        entries.append(DailyEntry(id: Date.todayKey(), steps: todaySteps, cyclingKm: todayKm, date: .now))

        return WeekChartModel(
            weekEntries: entries,
            startWeekday: startWeekday,
            todaySteps: todaySteps,
            todayKm: todayKm
        )
    }
}
