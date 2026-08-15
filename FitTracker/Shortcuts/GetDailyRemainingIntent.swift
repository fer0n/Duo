import AppIntents
import Foundation

struct GetDailyRemainingIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Daily Remaining"
    static var description = IntentDescription(
        "Returns how many steps and kilometers are left for today's challenge goal, plus the percentage remaining."
    )
    static var openAppWhenRun = false

    func perform() async throws -> some ReturnsValue<DailyRemainingResult> & ProvidesDialog {
        let result = await computeRemaining()
        let dialog: IntentDialog
        if result.percentageRemaining == 0 {
            dialog = "Daily goal complete!"
        } else {
            let stepsText = result.remainingSteps == 0
                ? String(localized: "no steps")
                : String(localized: "\(result.remainingSteps) steps")
            let kmText = result.remainingKm == 0
                ? String(localized: "no cycling")
                : String(localized: "\(result.remainingKm, specifier: "%.1f") km")
            dialog = "\(result.percentageRemaining)% remaining — \(stepsText) and \(kmText)."
        }
        return .result(value: result, dialog: dialog)
    }

    private func computeRemaining() async -> DailyRemainingResult {
        let defaults = UserDefaults(suiteName: "group.net.octabits.FitTracker") ?? .standard

        var settings = ChallengeSettings()
        if let data = defaults.data(forKey: "challengeSettings"),
           let decoded = try? JSONDecoder().decode(ChallengeSettings.self, from: data) {
            settings = decoded
        }

        let hk = HealthKitManager.shared
        try? await hk.requestAuthorization()

        let weekStart = Calendar.current.currentWeekStart(startingOn: settings.challengeStartWeekday)
        let liveEntries = await hk.fetchWeeklyEntries(from: weekStart)

        // HealthKit returns all-zero entries when the device is locked (encrypted store).
        // Fall back to the UserDefaults cache written by background delivery.
        let entries: [String: DailyEntry]
        if liveEntries.values.contains(where: { $0.steps > 0 || $0.cyclingKm > 0 }) {
            entries = liveEntries
        } else if let data = defaults.data(forKey: "dailyEntries"),
                  let cached = try? JSONDecoder().decode([String: DailyEntry].self, from: data) {
            entries = cached
        } else {
            entries = liveEntries
        }

        let weekEntries = entries.values.filter { $0.date >= weekStart }
        let weeklySteps = weekEntries.reduce(0) { $0 + $1.steps }
        let weeklyKm = weekEntries.reduce(0.0) { $0 + $1.cyclingKm }
        let todaySteps = entries[Date.todayKey()]?.steps ?? 0
        let todayKm = entries[Date.todayKey()]?.cyclingKm ?? 0.0

        let remainingDays = Calendar.current.remainingDaysInChallengeWeek(startingOn: settings.challengeStartWeekday)
        let prevProgress = ProgressCalculator.weeklyProgress(
            steps: weeklySteps - todaySteps,
            km: weeklyKm - todayKm
        )
        let goal = ProgressCalculator.dailyTarget(weeklyProgress: prevProgress, remainingDays: remainingDays)

        let stepsFraction = goal.steps > 0 ? Double(todaySteps) / Double(goal.steps) : 1.0
        let kmFraction = goal.km > 0 ? todayKm / goal.km : 1.0
        let missingFraction = max(0.0, 1.0 - (stepsFraction + kmFraction))

        return DailyRemainingResult(
            remainingSteps: Int((missingFraction * Double(goal.steps)).rounded()),
            remainingKm: (missingFraction * goal.km * 10).rounded() / 10,
            percentageRemaining: Int((missingFraction * 100).rounded())
        )
    }
}
