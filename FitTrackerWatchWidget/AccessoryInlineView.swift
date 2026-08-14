import SwiftUI
import WidgetKit

/// Inline complication: weekly percentage plus what's still left for today.
struct AccessoryInlineView: View {
    let entry: FitChallengeEntry

    private var text: String {
        let percent = Int((entry.weeklyProgress * 100).rounded())
        guard entry.weeklyProgress < 1.0 else { return "\(percent)% · done" }
        guard entry.dailyTargetSteps > 0 || entry.dailyTargetKm > 0 else { return "\(percent)%" }
        let remainingSteps = max(entry.dailyTargetSteps - entry.todaySteps, 0)
        let remainingKm = max(entry.dailyTargetKm - entry.todayKm, 0)
        return "\(percent)% · \(ProgressCalculator.dailyTargetText(steps: remainingSteps, km: remainingKm)) left"
    }

    var body: some View {
        Label(text, systemImage: "figure.run")
            .widgetURL(URL(string: "fittracker://open"))
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
