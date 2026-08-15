import WidgetKit
import SwiftUI

/// Medium widget — today's activity by hour.
struct HourlyActivityWidget: Widget {
    let kind = "HourlyActivity"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitWidgetProvider()) { entry in
            HourlyActivityWidgetView(entry: entry)
                .containerBackground(Color(.secondarySystemBackground), for: .widget)
        }
        .configurationDisplayName("Hourly")
        .description("Today's steps and cycling, hour by hour.")
        .supportedFamilies([.systemMedium])
    }
}

struct HourlyActivityWidgetView: View {
    let entry: FitWidgetEntry

    private var todayPercent: Int {
        Int((entry.dailyStepsFraction + entry.dailyKmFraction) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .firstTextBaseline, spacing: 15) {
                Text("\(todayPercent)%")
                    .font(.title)
                    .fontWeight(.bold)
                    .fontWidth(.compressed)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: Const.Symbol.steps)
                    Text(entry.todaySteps.formatted())
                }
                .foregroundStyle(.secondary)
                HStack(spacing: 2) {
                    Image(systemName: Const.Symbol.cycling)
                    Text("\(entry.todayKm.kmFormatted) km")
                }
                .foregroundStyle(.secondary)
            }
            .font(.headline.weight(.bold))
            .monospacedDigit()
            .fontWidth(.condensed)

            HourlyChartView(hourlyActivity: entry.hourly, animates: false)
        }
    }
}

#Preview(as: .systemMedium) {
    HourlyActivityWidget()
} timeline: {
    WidgetSampleData.entry
}
