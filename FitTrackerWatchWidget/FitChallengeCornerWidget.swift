import SwiftUI
import WidgetKit

/// Corner complication for Nike Hybrid face.
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
