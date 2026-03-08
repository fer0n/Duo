import HealthKit
import Foundation

final class HealthKitManager {
    static let shared = HealthKitManager()
    private init() {}

    private let healthStore = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard Self.isAvailable else { return }
        try await healthStore.requestAuthorization(
            toShare: [],
            read: [HKQuantityType(.stepCount), HKQuantityType(.distanceCycling)]
        )
    }

    // MARK: - Fetch

    func fetchWeeklyEntries(from weekStart: Date) async -> [String: DailyEntry] {
        guard Self.isAvailable else { return [:] }

        async let stepsMap = fetchDailyTotals(
            type: HKQuantityType(.stepCount), unit: .count(), from: weekStart
        )
        async let kmMap = fetchDailyTotals(
            type: HKQuantityType(.distanceCycling), unit: HKUnit(from: "km"), from: weekStart
        )

        let (steps, km) = await (stepsMap, kmMap)

        var result: [String: DailyEntry] = [:]
        let cal = Calendar.current
        var day = cal.startOfDay(for: weekStart)
        let today = cal.startOfDay(for: .now)
        while day <= today {
            let key = Self.dateKey(day)
            result[key] = DailyEntry(
                id: key,
                steps: steps[key].map(Int.init) ?? 0,
                cyclingKm: km[key] ?? 0.0,
                date: day
            )
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        return result
    }

    private func fetchDailyTotals(
        type: HKQuantityType, unit: HKUnit, from start: Date
    ) async -> [String: Double] {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: start, end: .now, options: .strictStartDate
            )
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: Calendar.current.startOfDay(for: start),
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, collection, _ in
                var result: [String: Double] = [:]
                collection?.enumerateStatistics(from: start, to: .now) { stats, _ in
                    if let sum = stats.sumQuantity() {
                        result[Self.dateKey(stats.startDate)] = sum.doubleValue(for: unit)
                    }
                }
                continuation.resume(returning: result)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Live Updates

    func enableBackgroundDelivery() {
        guard Self.isAvailable else { return }
        healthStore.enableBackgroundDelivery(
            for: HKQuantityType(.stepCount), frequency: .immediate
        ) { _, _ in }
        healthStore.enableBackgroundDelivery(
            for: HKQuantityType(.distanceCycling), frequency: .immediate
        ) { _, _ in }
    }

    func startObserving(onChange: @escaping @Sendable () -> Void) {
        guard Self.isAvailable else { return }
        for type in [HKQuantityType(.stepCount), HKQuantityType(.distanceCycling)] {
            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, _, error in
                guard error == nil else { return }
                onChange()
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Helpers

    static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
