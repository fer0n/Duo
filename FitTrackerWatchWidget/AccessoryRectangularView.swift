import SwiftUI
import WidgetKit

/// Nike face complication: segmented progress bar + daily target text.
struct AccessoryRectangularView: View {
    let entry: FitChallengeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Header row
            HStack(alignment: .firstTextBaseline) {
                Text("FitChallenge")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .widgetAccentable()
                Spacer()
                Text("\(Int(entry.weeklyProgress * 100))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            // Segmented progress bar
            ComplicationProgressBar(
                stepsContrib: entry.stepsContrib,
                cyclingContrib: entry.cyclingContrib
            )

            // Daily target
            Text(entry.dailyTargetText)
                .font(.caption2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 2)
        .widgetURL(URL(string: "fittracker://open"))
    }
}

// MARK: - Progress Bar for Complication

struct ComplicationProgressBar: View {
    let stepsContrib: Double
    let cyclingContrib: Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 8)

                if stepsContrib > 0 {
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: width * min(stepsContrib, 1.0), height: 8)
                }

                if cyclingContrib > 0 {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: 4
                    )
                    .fill(Color.green)
                    .frame(width: width * min(cyclingContrib, 1.0 - stepsContrib), height: 8)
                    .offset(x: width * stepsContrib)
                }
            }
        }
        .frame(height: 8)
    }
}

#Preview(as: .accessoryRectangular) {
    FitChallengeRectangularWidget()
} timeline: {
    FitChallengeEntry(
        date: .now,
        weeklyProgress: 0.65,
        stepsContrib: 0.4,
        cyclingContrib: 0.25,
        dailyTargetText: "5.8k steps + 3.9km"
    )
    FitChallengeEntry(
        date: .now,
        weeklyProgress: 0.0,
        stepsContrib: 0.0,
        cyclingContrib: 0.0,
        dailyTargetText: "8.6k steps + 5.7km"
    )
}
