import WidgetKit
import SwiftUI

/// Medium widget — the weekly bar chart from the watch app's second page.
struct WeekChartWidget: Widget {
    let kind = "WeekChart"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitWidgetProvider()) { entry in
            WeekChartWidgetView(entry: entry)
                .containerBackground(Color(.secondarySystemBackground), for: .widget)
        }
        .configurationDisplayName("Week")
        .description("Daily progress across the challenge week.")
        .supportedFamilies([.systemMedium])
    }
}

struct WeekChartWidgetView: View {
    let entry: FitWidgetEntry

    private var projection: (steps: Int, km: Double)? {
        guard let next = entry.weekDays.first(where: \.isNextDay) else { return nil }
        guard next.goalSteps > 0 || next.goalKm > 0 else { return nil }
        return (next.goalSteps, next.goalKm)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(entry.weekHeader)
                    .font(.headline)
                Spacer()
                if let projection {
                    Label(ProgressCalculator.stepsText(projection.steps), systemImage: "figure.run")
                        .foregroundStyle(Color.accentColor)
                    Label("\(projection.km.kmFormatted) km", systemImage: "figure.outdoor.cycle")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption.weight(.bold))
            .monospacedDigit()
            .fontWidth(.condensed)

            WeekChart(
                days: entry.weekDays,
                highlightNextDay: true
            )
        }
    }
}

#Preview(as: .systemMedium) {
    WeekChartWidget()
} timeline: {
    WidgetSampleData.entry
}
