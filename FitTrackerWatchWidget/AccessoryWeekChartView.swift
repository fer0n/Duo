import SwiftUI
import WidgetKit

/// The weekly bar chart from the watch app's second page, shrunk to a complication:
/// header, tomorrow's target, and one bar per day against the dashed goal line.
struct AccessoryWeekChartView: View {
    let entry: WeekChartEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(entry.header)
                Spacer(minLength: 0)
                if let target = entry.nextTarget {
                    Text(ProgressCalculator.stepsText(target.steps))
                        .foregroundStyle(Color.accentColor)
                        .widgetAccentable()

                    Text("\(target.km.kmFormatted) km")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 13, weight: .bold))
            .monospacedDigit()
            .fontWidth(.condensed)
            .lineLimit(1)
            // No minimumScaleFactor: it scales each Text on its own, which left the
            // header label smaller than the numbers next to it.

            WeekChart(
                days: entry.days,
                highlightNextDay: true,
                compact: true
            )
        }
        .widgetURL(URL(string: "fittracker://open"))
    }
}

#Preview(as: .accessoryRectangular) {
    FitChallengeWeekChartWidget()
} timeline: {
    let model = WeekChartSampleData.model
    let next = model.days.first(where: \.isNextDay)
    WeekChartEntry(
        date: .now,
        days: model.days,
        header: model.headerLabel,
        nextTarget: next.map { ($0.goalSteps, $0.goalKm) }
    )
}
