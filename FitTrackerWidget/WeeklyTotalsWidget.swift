import WidgetKit
import SwiftUI

/// Medium widget — the watch app's "Week" page: combined bar plus steps and cycling totals.
struct WeeklyTotalsWidget: Widget {
    let kind = "WeeklyTotals"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitWidgetProvider()) { entry in
            WeeklyTotalsWidgetView(entry: entry)
                .containerBackground(Color(.secondarySystemBackground), for: .widget)
        }
        .configurationDisplayName("This Week")
        .description("Weekly steps and cycling against your goals.")
        .supportedFamilies([.systemMedium])
    }
}

struct WeeklyTotalsWidgetView: View {
    let entry: FitWidgetEntry

    var body: some View {
        ActivityPageView(
            config: ActivityPageConfig(
                label: "Week",
                stepsFraction: entry.weeklyStepsFraction,
                kmFraction: entry.weeklyKmFraction,
                steps: entry.weeklySteps,
                km: entry.weeklyKm,
                goalSteps: entry.weekGoalSteps,
                goalKm: entry.weekGoalKm
            ),
            animates: false
        )
    }
}

#Preview(as: .systemMedium) {
    WeeklyTotalsWidget()
} timeline: {
    WidgetSampleData.entry
}
