import Foundation

enum ProgressCalculator {
    static let defaultStepGoal: Double = 60_000
    static let defaultKmGoal: Double = 40.0

    /// User-adjustable weekly goals, read from the shared app group so widgets and the
    /// watch app stay in sync with the iOS settings screen.
    static var stepGoal: Double {
        AppGroup.defaults.object(forKey: AppGroup.stepGoalKey) as? Double ?? defaultStepGoal
    }

    static var kmGoal: Double {
        AppGroup.defaults.object(forKey: AppGroup.kmGoalKey) as? Double ?? defaultKmGoal
    }

    /// Persists the goals so every process (widgets included) picks them up.
    static func storeGoals(steps: Double, km: Double) {
        AppGroup.defaults.set(steps, forKey: AppGroup.stepGoalKey)
        AppGroup.defaults.set(km, forKey: AppGroup.kmGoalKey)
    }

    // A goal of 0 disables that activity — it then contributes nothing instead of dividing by zero.
    static func stepsFraction(_ steps: Int) -> Double {
        let goal = stepGoal
        return goal > 0 ? Double(steps) / goal : 0
    }

    static func kmFraction(_ km: Double) -> Double {
        let goal = kmGoal
        return goal > 0 ? km / goal : 0
    }

    // Raw combined weekly progress (uncapped)
    static func weeklyProgressRaw(steps: Int, km: Double) -> Double {
        stepsFraction(steps) + kmFraction(km)
    }

    // Combined weekly progress, capped at 1.0
    static func weeklyProgress(steps: Int, km: Double) -> Double {
        min(weeklyProgressRaw(steps: steps, km: km), 1.0)
    }

    // Steps fraction of the full bar (0...1)
    static func stepsContribution(steps: Int) -> Double {
        min(stepsFraction(steps), 1.0)
    }

    // Cycling fraction that fills after steps in the bar (0...1)
    static func cyclingContribution(km: Double, steps: Int) -> Double {
        let stepPortion = stepsContribution(steps: steps)
        let total = min(stepPortion + kmFraction(km), 1.0)
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

    // "8.5k"
    static func stepsText(_ steps: Int) -> String {
        steps >= 1000
            ? String(format: "%.1fk", Double(steps) / 1000)
            : "\(steps)"
    }

    // "8.5k steps + 4.0km"
    static func dailyTargetText(steps: Int, km: Double) -> String {
        "\(stepsText(steps)) steps + \(String(format: "%.1f", km))km"
    }
}
