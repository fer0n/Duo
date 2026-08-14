import WidgetKit
import SwiftUI

/// Small widget — mirrors the watch app's first page: today's gauge plus the two stats.
struct TodayProgressWidget: Widget {
    let kind = "TodayProgress"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitWidgetProvider()) { entry in
            TodayProgressWidgetView(entry: entry)
                .containerBackground(Color(.secondarySystemBackground), for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Today's progress toward the daily target.")
        .supportedFamilies([.systemSmall])
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
            compactStats: true
        )
    }
}

#Preview(as: .systemSmall) {
    TodayProgressWidget()
} timeline: {
    WidgetSampleData.entry
}
