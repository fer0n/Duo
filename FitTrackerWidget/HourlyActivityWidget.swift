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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Hourly")
                    .font(.headline)
                Spacer()
                Label(entry.todaySteps.formatted(), systemImage: "figure.run")
                    .foregroundStyle(Color.accentColor)
                Label("\(entry.todayKm.kmFormatted) km", systemImage: "figure.outdoor.cycle")
                    .foregroundStyle(kmBarColor)
            }
            .font(.caption.weight(.bold))
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
