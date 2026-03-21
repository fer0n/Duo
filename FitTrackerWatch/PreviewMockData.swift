#if DEBUG
import Foundation

extension ChallengeStore {

    /// Scenarios for cycling through today's step/km values in previews.
    static let previewScenarios: [(steps: Int, km: Double)] = [
        (0, 0),
        (1_000, 1.0),
        (4_200, 2.6),
        (5_000, 0),
        (0, 3.0),
        (22_000, 40.0)
    ]

    /// Scenarios for cycling through today's step/km values in previews.
    static let previewDoneScenarios: [(steps: Int, km: Double)] = [
        (0, 0),
        (63_000, 0)
    ]

    /// Returns a store pre-populated with realistic mock data for SwiftUI previews.
    static func preview(steps: Int = 4_200, km: Double = 2.6) -> ChallengeStore {
        let store = ChallengeStore(skipHealthKit: true)

        let hourlySteps = [0, 0, 0, 0, 0, 0, 80, 950, 1200, 400, 300, 200,
                           750, 600, 150, 200, 180, 300, 1100, 800, 400, 100, 50, 0]
        let hourlyKm: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                  0, 0, 0, 0, 0, 3.2, 4.1, 7.8, 0, 0, 0, 0]
        store.hourlyActivity = (0..<24).map { HourlyActivity(hour: $0, steps: hourlySteps[$0], km: hourlyKm[$0]) }

        let cal = Calendar.current
        let weekStart = cal.currentWeekStart(startingOn: store.settings.challengeStartWeekday)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let pastDays: [(steps: Int, km: Double)] = [
            (8_500, 1.3), (6_200, 1.3), (9_100, 0),
            (1200, 0), (500, 1.0), (4_300, 6.0)
        ]
        let todayStart = cal.startOfDay(for: .now)
        let todayKey = Date.todayKey()
        let todayIndex = max(0, min(cal.dateComponents([.day], from: weekStart, to: todayStart).day ?? 0, 6))

        var entries: [String: DailyEntry] = [:]
        for i in 0..<todayIndex {
            let date = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
            let key = fmt.string(from: date)
            let p = pastDays[i % pastDays.count]
            entries[key] = DailyEntry(id: key, steps: p.steps, cyclingKm: p.km, date: date)
        }
        entries[todayKey] = DailyEntry(id: todayKey, steps: steps, cyclingKm: km, date: .now)
        store.entries = entries

        return store
    }
}
#endif
