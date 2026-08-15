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

/// Steps and cycling share a single capsule: the cycling colour fills the whole
/// progress, the steps portion is painted over it, so only the outer ends round off.
struct ComplicationProgressBar: View {
    let stepsContrib: Double
    let cyclingContrib: Double

    private let barHeight: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let steps = min(max(stepsContrib, 0), 1)
            let total = min(steps + max(cyclingContrib, 0), 1)
            // Never narrower than the capsule is tall, or the fill collapses into a sliver.
            let fillWidth = total > 0 ? max(width * total, barHeight) : 0

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: barHeight)

                Capsule()
                    .fill(kmBarColor)
                    .frame(width: fillWidth, height: barHeight)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: width * steps)
                    }
                    .clipShape(Capsule())
            }
        }
        .frame(height: barHeight)
    }
}

#Preview(as: .accessoryRectangular) {
    FitChallengeRectangularWidget()
} timeline: {
    FitChallengeEntry(
        date: .now,
        weeklyProgress: 0.65,
        weeklyProgressRaw: 0.65,
        stepsContrib: 0.4,
        cyclingContrib: 0.25,
        dailyTargetText: "5.8k steps + 3.9km",
        dailyTargetSteps: 5800,
        dailyTargetKm: 3.9,
        weeklySteps: 24000,
        weeklyKm: 10.0,
        todaySteps: 3000,
        todayKm: 2.0
    )
    FitChallengeEntry(
        date: .now,
        weeklyProgress: 0.0,
        weeklyProgressRaw: 0.0,
        stepsContrib: 0.0,
        cyclingContrib: 0.0,
        dailyTargetText: "8.6k steps + 5.7km",
        dailyTargetSteps: 8600,
        dailyTargetKm: 5.7,
        weeklySteps: 0,
        weeklyKm: 0.0,
        todaySteps: 0,
        todayKm: 0.0
    )
}
