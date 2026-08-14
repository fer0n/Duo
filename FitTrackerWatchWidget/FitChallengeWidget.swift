import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct FitChallengeEntry: TimelineEntry {
    let date: Date
    let weeklyProgress: Double   // capped at 1.0 for normal progress display
    let weeklyProgressRaw: Double // uncapped, for post-goal gauge
    let stepsContrib: Double
    let cyclingContrib: Double
    let dailyTargetText: String
    let dailyTargetSteps: Int
    let dailyTargetKm: Double
    let weeklySteps: Int
    let weeklyKm: Double
    let todaySteps: Int
    let todayKm: Double
}

// MARK: - Timeline Provider

struct FitChallengeProvider: TimelineProvider {
    typealias Entry = FitChallengeEntry

    private func makeEntry(date: Date) -> FitChallengeEntry {
        let snapshot = ChallengeSnapshot()
        let target = snapshot.dailyTarget
        return FitChallengeEntry(
            date: date,
            weeklyProgress: snapshot.weeklyProgress,
            weeklyProgressRaw: snapshot.weeklyProgressRaw,
            stepsContrib: ProgressCalculator.stepsContribution(steps: snapshot.weeklySteps),
            cyclingContrib: ProgressCalculator.cyclingContribution(
                km: snapshot.weeklyKm, steps: snapshot.weeklySteps
            ),
            dailyTargetText: ProgressCalculator.dailyTargetText(steps: target.steps, km: target.km),
            dailyTargetSteps: target.steps,
            dailyTargetKm: target.km,
            weeklySteps: snapshot.weeklySteps,
            weeklyKm: snapshot.weeklyKm,
            todaySteps: snapshot.todaySteps,
            todayKm: snapshot.todayKm
        )
    }

    func placeholder(in context: Context) -> FitChallengeEntry {
        FitChallengeEntry(
            date: .now,
            weeklyProgress: 0.5,
            weeklyProgressRaw: 0.5,
            stepsContrib: 0.3,
            cyclingContrib: 0.2,
            dailyTargetText: "8.5k steps + 4.0km",
            dailyTargetSteps: 8500,
            dailyTargetKm: 4.0,
            weeklySteps: 18000,
            weeklyKm: 8.0,
            todaySteps: 3400,
            todayKm: 1.6
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
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("FitChallenge")
        .description("Weekly challenge progress bar")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Corner Widget (Nike Hybrid face)

struct FitChallengeCornerWidget: Widget {
    let kind = "FitChallengeCorner"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitChallengeProvider()) { entry in
            AccessoryCornerView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("FitChallenge")
        .description("Weekly progress with daily target")
        .supportedFamilies([.accessoryCorner])
    }
}

// MARK: - Circular Widget

struct FitChallengeCircularWidget: Widget {
    let kind = "FitChallengeCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitChallengeProvider()) { entry in
            AccessoryCircularView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("FitChallenge")
        .description("Weekly progress ring")
        .supportedFamilies([.accessoryCircular])
    }
}
