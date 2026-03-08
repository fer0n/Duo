import SwiftUI
import WidgetKit

/// Corner complication for Nike Hybrid face.
/// Curved text always shows today's daily target (remaining ÷ remaining days).
/// Before goal: ProgressView toward goal. After goal: Gauge showing how far past goal.
struct AccessoryCornerView: View {
    let entry: FitChallengeEntry

    private var goalReached: Bool { entry.weeklyProgress >= 1.0 }

    // Always shows daily target (remaining weekly goal ÷ remaining days).
    private var curvedText: String {
        let stepsK = String(format: "%.1f", Double(entry.dailyTargetSteps) / 1000)
        let km = String(format: "%.1f", entry.dailyTargetKm)
        if entry.dailyTargetSteps == 0 && entry.dailyTargetKm == 0 { return "Done" }
        if entry.dailyTargetSteps == 0 { return km }
        if entry.dailyTargetKm == 0 { return "\(stepsK)k" }
        return "\(stepsK)k+\(km)"
    }

    var body: some View {
        Text(curvedText)
            .font(.caption2)
            .minimumScaleFactor(0.7)
            .widgetCurvesContent()
            .widgetLabel {
                if goalReached {
                    // Gauge range extends beyond goal so you can see where 1.0 was
                    let gaugeMax = max(entry.weeklyProgressRaw, 1)
                    let goalMark = 1.0 / gaugeMax
                    Gauge(value: entry.weeklyProgressRaw, in: 0...gaugeMax) {
                        Text("")
                    } currentValueLabel: {
                        Text("")
                    }
                    .tint(Gradient(stops: [
                        .init(color: .green, location: 0),
                        .init(color: .green, location: goalMark),
                        .init(color: .green.opacity(0.45), location: goalMark + 0.01),
                        .init(color: .green.opacity(0.45), location: 1.0)
                    ]))
                } else {
                    ProgressView(value: entry.weeklyProgress) {
                        Text("")
                    } currentValueLabel: {
                        Text("")
                    }
                    .tint(.blue)
                }
            }
            .widgetURL(URL(string: "fittracker://open"))
    }
}

#Preview(as: .accessoryCorner) {
    FitChallengeCornerWidget()
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
        weeklyKm: 10.0
    )
    // Daily pacing overshot by ~50% (ahead of schedule), weekly goal not yet reached
    FitChallengeEntry(
        date: .now,
        weeklyProgress: 0.78,
        weeklyProgressRaw: 0.78,
        stepsContrib: 0.48,
        cyclingContrib: 0.30,
        dailyTargetText: "3.3k steps + 2.2km",
        dailyTargetSteps: 3300,
        dailyTargetKm: 2.2,
        weeklySteps: 28800,
        weeklyKm: 12.0
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
        weeklyKm: 14.7
    )
}
