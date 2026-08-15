import SwiftUI
import WidgetKit

/// Inline complication: weekly percentage plus today's tally, e.g. "65% • 4.2K + 2.6KM".
struct AccessoryInlineView: View {
    let entry: FitChallengeEntry

    private func stepsText(_ steps: Int) -> String {
        steps >= 1000
            ? "\((Double(steps) / 1000).formatted(.number.precision(.fractionLength(0...1))))K"
            : "\(steps)"
    }

    private func kmText(_ km: Double) -> String {
        "\(km.formatted(.number.precision(.fractionLength(0...1))))KM"
    }

    private var text: String {
        let percent = Int((entry.weeklyProgress * 100).rounded())
        guard entry.todaySteps > 0 || entry.todayKm > 0 else { return "\(percent)%" }
        return "\(percent)% • \(stepsText(entry.todaySteps)) + \(kmText(entry.todayKm))"
    }

    var body: some View {
        // Label is the one shape inline complications render with a symbol.
        if entry.weeklyProgress >= 1.0 {
            Label("Done", systemImage: "checkmark")
                .widgetURL(URL(string: "fittracker://open"))
                .labelStyle(.titleOnly)
        } else {
            Text(text)
                .widgetURL(URL(string: "fittracker://open"))
        }
    }
}

#Preview(as: .accessoryInline) {
    FitChallengeInlineWidget()
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
        weeklyProgress: 1.0,
        weeklyProgressRaw: 1.18,
        stepsContrib: 0.6,
        cyclingContrib: 0.4,
        dailyTargetText: "0 steps + 0.0km",
        dailyTargetSteps: 0,
        dailyTargetKm: 0.0,
        weeklySteps: 62000,
        weeklyKm: 14.7,
        todaySteps: 0,
        todayKm: 0.0
    )
}
