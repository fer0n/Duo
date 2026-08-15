import SwiftUI
import WidgetKit

struct FitChallengeWeekChartWidget: Widget {
    let kind = "FitChallengeWeekChart"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeekChartProvider()) { entry in
            AccessoryWeekChartView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Week")
        .description("Daily progress across the challenge week")
        .supportedFamilies([.accessoryRectangular])
    }
}
