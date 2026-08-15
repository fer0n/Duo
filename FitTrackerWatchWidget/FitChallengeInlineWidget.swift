import SwiftUI
import WidgetKit

struct FitChallengeInlineWidget: Widget {
    let kind = "FitChallengeInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitChallengeProvider()) { entry in
            AccessoryInlineView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("FitChallenge")
        .description("Weekly progress and what's left today")
        .supportedFamilies([.accessoryInline])
    }
}
