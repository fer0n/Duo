import SwiftUI
import WidgetKit

/// Circular ring complication showing combined weekly progress.
struct AccessoryCircularView: View {
    let entry: FitChallengeEntry

    var body: some View {
        Gauge(value: entry.weeklyProgress, in: 0...1) {
            Image(systemName: "figure.run")
                .font(.caption2)
        } currentValueLabel: {
            Text("\(Int(entry.weeklyProgress * 100))%")
                .font(.system(size: 11, weight: .semibold))
                .monospacedDigit()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(entry.weeklyProgress >= 1.0 ? .green : .accentColor)
        .widgetURL(URL(string: "fittracker://open"))
    }
}

#Preview(as: .accessoryCircular) {
    FitChallengeCircularWidget()
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
}
