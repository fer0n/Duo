import SwiftUI
import WidgetKit

/// Nike face complication (main).
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
