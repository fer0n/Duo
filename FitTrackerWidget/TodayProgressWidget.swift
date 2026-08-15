import WidgetKit
import SwiftUI
import AppIntents

/// Small widget — mirrors the watch app's first page: today's gauge plus the two stats.
struct TodayProgressWidget: Widget {
    let kind = "TodayProgress"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TodayProgressConfigurationIntent.self,
            provider: TodayProgressProvider()
        ) { entry in
            TodayProgressWidgetView(entry: entry)
                .containerBackground(Color(.secondarySystemBackground), for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Today's progress toward the daily target.")
        .supportedFamilies([.systemSmall])
    }
}

struct TodayProgressConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Today"
    static var description = IntentDescription("Today's progress toward the daily target.")

    @Parameter(title: "Show Steps & KM", default: true)
    var showStats: Bool
}

struct TodayProgressProvider: AppIntentTimelineProvider {
    typealias Entry = FitWidgetEntry
    typealias Intent = TodayProgressConfigurationIntent

    func placeholder(in context: Context) -> FitWidgetEntry {
        WidgetSampleData.entry
    }

    func snapshot(for configuration: TodayProgressConfigurationIntent, in context: Context) async -> FitWidgetEntry {
        var entry = context.isPreview
            ? WidgetSampleData.entry
            : FitWidgetEntry(date: .now, snapshot: ChallengeSnapshot())
        entry.showStats = configuration.showStats
        return entry
    }

    func timeline(
        for configuration: TodayProgressConfigurationIntent,
        in context: Context
    ) async -> Timeline<FitWidgetEntry> {
        var entry = FitWidgetEntry(date: .now, snapshot: ChallengeSnapshot())
        entry.showStats = configuration.showStats
        // Refresh at the top of the next hour
        let nextUpdate = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date(timeIntervalSinceNow: 3600)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct TodayProgressWidgetView: View {
    let entry: FitWidgetEntry

    var body: some View {
        WatchGaugeView(
            stepsFraction: entry.dailyStepsFraction,
            kmFraction: entry.dailyKmFraction,
            todaySteps: entry.todaySteps,
            todayKm: entry.todayKm,
            goalSteps: entry.dailyGoalSteps,
            goalKm: entry.dailyGoalKm,
            isWeeklyGoalReached: entry.weeklyGoalReached,
            animates: false,
            gaugeInset: 0,
            compactStats: true,
            showStats: entry.showStats
        )
    }
}

#Preview(as: .systemSmall) {
    TodayProgressWidget()
} timeline: {
    WidgetSampleData.entry
}
