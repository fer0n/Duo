import SwiftUI
import WidgetKit

struct FitChallengeCircularWidget: Widget {
    let kind = "FitChallengeCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitChallengeProvider()) { entry in
            AccessoryCircularView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("FitChallenge")
        .description("Weekly progress ring")
        .supportedFamilies([.accessoryCircular])
    }
}
