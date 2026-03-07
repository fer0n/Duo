import SwiftUI
import WidgetKit

/// Corner complication for Nike Hybrid face.
/// Progress bar always shows today's progress toward the daily goal.
/// Curved text: "Done" (weekly done), "+X%" overshoot (daily done), or the daily target.
struct AccessoryCornerView: View {
    let entry: FitChallengeEntry

    private var weeklyDone: Bool { entry.weeklyProgress >= 1.0 }

    /// Ratio of today's activity to the daily goal (1.0 = exactly met, >1.0 = overshot).
    private var dailyProgressRaw: Double {
        let goalUnits = Double(entry.dailyTargetSteps) / ProgressCalculator.stepGoal
            + entry.dailyTargetKm / ProgressCalculator.kmGoal
        guard goalUnits > 0 else { return 0 }
        let todayUnits = Double(entry.todaySteps) / ProgressCalculator.stepGoal
            + entry.todayKm / ProgressCalculator.kmGoal
        return todayUnits / goalUnits
    }

    private var dailyDone: Bool { dailyProgressRaw >= 1.0 }

    private var curvedText: String {
        if weeklyDone { return "Done" }
        let stepsK = String(format: "%.1f", Double(entry.todaySteps) / 1000)
        let km = String(format: "%.0f", entry.todayKm)
        if entry.todaySteps == 0 && entry.todayKm == 0 { return "0" }
        if entry.todaySteps == 0 { return km }
        if entry.todayKm == 0 { return "\(stepsK)k" }
        return "\(stepsK)k + \(km)"
    }

    var body: some View {
        Text(curvedText)
            .font(.caption2)
            .minimumScaleFactor(0.7)
            .widgetCurvesContent()
            .widgetLabel {
                if weeklyDone {
                    // value = goal (1.0), max = how far past goal — bar fills to where goal sits
                    Gauge(value: 1.0, in: 0...max(entry.weeklyProgressRaw, 1)) {
                        Text("")
                    } currentValueLabel: {
                        Text("")
                    }
                    .tint(.green)
                } else if dailyDone {
                    Gauge(value: 1.0, in: 0...dailyProgressRaw) {
                        Text("")
                    } currentValueLabel: {
                        Text("")
                    }
                    .tint(.blue)
                } else {
                    ProgressView(value: dailyProgressRaw) {
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
    // 65% weekly done, today ~50% through daily target
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
        todaySteps: 2900,
        todayKm: 1.95
    )
    // 78% weekly done, daily goal overshot by 50% (todayUnits = 1.5 × dailyGoalUnits)
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
        weeklyKm: 12.0,
        todaySteps: 4950,
        todayKm: 3.3
    )
    // Weekly goal done
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
