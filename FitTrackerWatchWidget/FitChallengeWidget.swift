import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct FitChallengeEntry: TimelineEntry {
    let date: Date
    let weeklyProgress: Double
    let stepsContrib: Double
    let cyclingContrib: Double
    let dailyTargetText: String
}

// MARK: - Nonisolated data reader for widget (avoids @MainActor ChallengeStore)

private struct WidgetDataReader {
    let settings: ChallengeSettings
    let weeklySteps: Int
    let weeklyKm: Double

    init() {
        let defaults = UserDefaults(suiteName: "group.com.pentlandFirth.FitTracker") ?? .standard
        if let data = defaults.data(forKey: "challengeSettings"),
           let decoded = try? JSONDecoder().decode(ChallengeSettings.self, from: data) {
            settings = decoded
        } else {
            settings = ChallengeSettings()
        }
        if let data = defaults.data(forKey: "dailyEntries"),
           let entries = try? JSONDecoder().decode([String: DailyEntry].self, from: data) {
            let weekStart = Calendar.current.currentWeekStart(startingOn: settings.challengeStartWeekday)
            let weekEntries = entries.values.filter { $0.date >= weekStart }
            weeklySteps = weekEntries.reduce(0) { $0 + $1.steps }
            weeklyKm = weekEntries.reduce(0.0) { $0 + $1.cyclingKm }
        } else {
            weeklySteps = 0
            weeklyKm = 0
        }
    }
}

// MARK: - Timeline Provider

struct FitChallengeProvider: TimelineProvider {
    typealias Entry = FitChallengeEntry

    private func makeEntry(date: Date) -> FitChallengeEntry {
        let reader = WidgetDataReader()
        let progress = ProgressCalculator.weeklyProgress(steps: reader.weeklySteps, km: reader.weeklyKm)
        let remaining = Calendar.current.remainingDaysInChallengeWeek(
            startingOn: reader.settings.challengeStartWeekday
        )
        let target = ProgressCalculator.dailyTarget(weeklyProgress: progress, remainingDays: remaining)
        return FitChallengeEntry(
            date: date,
            weeklyProgress: progress,
            stepsContrib: ProgressCalculator.stepsContribution(steps: reader.weeklySteps),
            cyclingContrib: ProgressCalculator.cyclingContribution(km: reader.weeklyKm, steps: reader.weeklySteps),
            dailyTargetText: ProgressCalculator.dailyTargetText(steps: target.steps, km: target.km)
        )
    }

    func placeholder(in context: Context) -> FitChallengeEntry {
        FitChallengeEntry(
            date: .now,
            weeklyProgress: 0.5,
            stepsContrib: 0.3,
            cyclingContrib: 0.2,
            dailyTargetText: "8.5k steps + 4.0km"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FitChallengeEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : makeEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FitChallengeEntry>) -> Void) {
        let entry = makeEntry(date: .now)
        // Refresh at the top of the next hour
        let nextUpdate = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date(timeIntervalSinceNow: 3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Rectangular Widget (main Nike face complication)

struct FitChallengeRectangularWidget: Widget {
    let kind = "FitChallengeRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitChallengeProvider()) { entry in
            AccessoryRectangularView(entry: entry)
        }
        .configurationDisplayName("FitChallenge")
        .description("Weekly challenge progress bar")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Circular Widget

struct FitChallengeCircularWidget: Widget {
    let kind = "FitChallengeCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitChallengeProvider()) { entry in
            AccessoryCircularView(entry: entry)
        }
        .configurationDisplayName("FitChallenge")
        .description("Weekly progress ring")
        .supportedFamilies([.accessoryCircular])
    }
}
