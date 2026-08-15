import Foundation

/// Realistic stand-in data for placeholders and previews.
enum WidgetSampleData {
    static let hourlySteps = [0, 0, 0, 0, 0, 0, 80, 950, 1200, 400, 300, 200,
                              750, 600, 150, 200, 180, 300, 1100, 800, 400, 100, 50, 0]
    static let hourlyKm: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 3.2, 4.1, 1.8, 0, 0, 0, 0]

    static var entry: FitWidgetEntry {
        FitWidgetEntry(date: .now, snapshot: snapshot)
    }

    /// A snapshot backed by an in-memory defaults suite so previews never touch real data.
    static var snapshot: ChallengeSnapshot {
        let defaults = UserDefaults(suiteName: "FitTrackerWidgetPreview") ?? .standard
        let cal = Calendar.current
        let weekStart = cal.currentWeekStart(startingOn: ChallengeSettings().challengeStartWeekday)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let pastDays: [(steps: Int, km: Double)] = [
            (8_500, 1.3), (6_200, 1.3), (9_100, 0),
            (1_200, 0), (500, 1.0), (4_300, 6.0)
        ]
        let todayStart = cal.startOfDay(for: .now)
        let todayIndex = max(0, min(cal.dateComponents([.day], from: weekStart, to: todayStart).day ?? 0, 6))

        var entries: [String: DailyEntry] = [:]
        for i in 0..<todayIndex {
            let date = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
            let key = formatter.string(from: date)
            let day = pastDays[i % pastDays.count]
            entries[key] = DailyEntry(id: key, steps: day.steps, cyclingKm: day.km, date: date)
        }
        let todayKey = Date.todayKey()
        entries[todayKey] = DailyEntry(id: todayKey, steps: 4_200, cyclingKm: 2.6, date: .now)

        let hourly = (0..<24).map { HourlyActivity(hour: $0, steps: hourlySteps[$0], km: hourlyKm[$0]) }

        defaults.set(try? JSONEncoder().encode(entries), forKey: AppGroup.entriesKey)
        defaults.set(try? JSONEncoder().encode(hourly), forKey: AppGroup.hourlyKey)
        defaults.set(todayKey, forKey: AppGroup.hourlyDayKey)
        defaults.set(try? JSONEncoder().encode(ChallengeSettings()), forKey: AppGroup.settingsKey)

        return ChallengeSnapshot(defaults: defaults)
    }
}
