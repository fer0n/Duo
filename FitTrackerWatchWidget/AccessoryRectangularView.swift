import SwiftUI
import WidgetKit

/// Nike face complication: weekly progress bar + today's steps and cycling
/// against their daily targets.
struct AccessoryRectangularView: View {
    let entry: FitChallengeEntry

    private func thousands(_ steps: Int) -> String {
        (Double(steps) / 1000).formatted(.number.precision(.fractionLength(0...1)))
    }

    private func km(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    /// A goal of 0 means nothing is left to do, so it counts as complete.
    private func percent(_ value: Double, of target: Double) -> Int {
        guard target > 0 else { return 100 }
        return Int((value / target * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ComplicationProgressBar(
                stepsContrib: entry.stepsContrib,
                cyclingContrib: entry.cyclingContrib
            )

            StatRow(
                systemImage: Const.Symbol.steps,
                current: thousands(entry.todaySteps),
                target: thousands(entry.dailyTargetSteps),
                unit: "k",
                percent: percent(Double(entry.todaySteps), of: Double(entry.dailyTargetSteps))
            )

            StatRow(
                systemImage: Const.Symbol.cycling,
                current: km(entry.todayKm),
                target: km(entry.dailyTargetKm),
                unit: "km",
                percent: percent(entry.todayKm, of: entry.dailyTargetKm)
            )
        }
        .padding(.horizontal, 2)
        .widgetURL(URL(string: "fittracker://open"))
    }
}

// MARK: - Stat Row

/// One activity: symbol, today's value against its target, and how far along that is.
private struct StatRow: View {
    let systemImage: String
    let current: String
    let target: String
    let unit: String
    let percent: Int

    /// Separator stays dim so the two numbers carry the row.
    private var value: Text {
        Text(current)
            + Text("/").foregroundStyle(.secondary)
            + Text(target)
            + Text(unit)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Image(systemName: systemImage)
                // figure.outdoor.cycle is wider than figure.run — a fixed column
                // keeps both values starting at the same x.
                .frame(width: 25)
            value
                .font(.caption2)
                .fontWeight(.semibold)
                .widgetAccentable()

            Spacer()

            Text("\(percent)%")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
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
