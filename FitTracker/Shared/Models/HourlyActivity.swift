import Foundation

/// One hour of today's activity. Persisted to the app group so widgets can render
/// the hourly chart without touching HealthKit themselves.
struct HourlyActivity: Identifiable, Equatable, Codable {
    let hour: Int
    let steps: Int
    let km: Double

    var id: Int { hour }
    var date: Date { Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now }
    var units: Double { ProgressCalculator.weeklyProgressRaw(steps: steps, km: km) }
}
