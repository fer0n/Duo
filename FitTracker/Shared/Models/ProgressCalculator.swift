import Foundation

enum ProgressCalculator {
    static let stepGoal: Double = 60_000
    static let kmGoal: Double = 40.0

    // Combined weekly progress, capped at 1.0
    static func weeklyProgress(steps: Int, km: Double) -> Double {
        let raw = Double(steps) / stepGoal + km / kmGoal
        return min(raw, 1.0)
    }

    // Steps fraction of the full bar (0...1)
    static func stepsContribution(steps: Int) -> Double {
        min(Double(steps) / stepGoal, 1.0)
    }

    // Cycling fraction that fills after steps in the bar (0...1)
    static func cyclingContribution(km: Double, steps: Int) -> Double {
        let stepPortion = min(Double(steps) / stepGoal, 1.0)
        let total = min(stepPortion + km / kmGoal, 1.0)
        return max(total - stepPortion, 0.0)
    }

    // Daily target split 50/50 between steps and cycling equivalents
    static func dailyTarget(weeklyProgress: Double, remainingDays: Int) -> (steps: Int, km: Double) {
        guard remainingDays > 0 else { return (0, 0.0) }
        let remaining = max(1.0 - weeklyProgress, 0.0)
        let daily = remaining / Double(remainingDays)
        let steps = Int((daily * stepGoal).rounded())
        let km = (daily * kmGoal * 10).rounded() / 10
        return (steps, km)
    }

    // "8.5k steps + 4.0km"
    static func dailyTargetText(steps: Int, km: Double) -> String {
        let stepsText = steps >= 1000
            ? String(format: "%.1fk", Double(steps) / 1000)
            : "\(steps)"
        return "\(stepsText) steps + \(String(format: "%.1f", km))km"
    }
}
