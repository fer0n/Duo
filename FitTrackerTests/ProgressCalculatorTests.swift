import Testing
@testable import FitTracker

struct ProgressCalculatorTests {

    // MARK: - weeklyProgress

    @Test func weeklyProgress_stepsOnly() {
        #expect(ProgressCalculator.weeklyProgress(steps: 30_000, km: 0) == 0.5)
    }

    @Test func weeklyProgress_kmOnly() {
        #expect(ProgressCalculator.weeklyProgress(steps: 0, km: 20) == 0.5)
    }

    @Test func weeklyProgress_mixed50_50() {
        let p = ProgressCalculator.weeklyProgress(steps: 30_000, km: 20)
        #expect(abs(p - 1.0) < 0.001)
    }

    @Test func weeklyProgress_cappedAt100() {
        let p = ProgressCalculator.weeklyProgress(steps: 60_000, km: 40)
        #expect(p == 1.0)
    }

    @Test func weeklyProgress_overGoalCapped() {
        let p = ProgressCalculator.weeklyProgress(steps: 120_000, km: 80)
        #expect(p == 1.0)
    }

    @Test func weeklyProgress_zero() {
        #expect(ProgressCalculator.weeklyProgress(steps: 0, km: 0) == 0.0)
    }

    // MARK: - stepsContribution

    @Test func stepsContrib_halfGoal() {
        #expect(ProgressCalculator.stepsContribution(steps: 30_000) == 0.5)
    }

    @Test func stepsContrib_capped() {
        #expect(ProgressCalculator.stepsContribution(steps: 120_000) == 1.0)
    }

    // MARK: - cyclingContribution

    @Test func cyclingContrib_noSteps() {
        let c = ProgressCalculator.cyclingContribution(km: 20, steps: 0)
        #expect(abs(c - 0.5) < 0.001)
    }

    @Test func cyclingContrib_withSteps() {
        // 30k steps = 50% bar already used; 10km cycling = 25% more
        let c = ProgressCalculator.cyclingContribution(km: 10, steps: 30_000)
        #expect(abs(c - 0.25) < 0.001)
    }

    @Test func cyclingContrib_cappedByTotal() {
        // Steps already at 80%, cycling would push to 130% → capped at 20%
        let c = ProgressCalculator.cyclingContribution(km: 40, steps: 48_000)
        #expect(abs(c - 0.2) < 0.001)
    }

    // MARK: - dailyTarget

    @Test func dailyTarget_weekStart_noProgress() {
        let (steps, km) = ProgressCalculator.dailyTarget(weeklyProgress: 0.0, remainingDays: 7)
        #expect(steps == Int((60_000.0 / 7).rounded()))
        #expect(abs(km - (40.0 / 7 * 10).rounded() / 10) < 0.05)
    }

    @Test func dailyTarget_lastDay_halfDone() {
        let (steps, km) = ProgressCalculator.dailyTarget(weeklyProgress: 0.5, remainingDays: 1)
        #expect(steps == 30_000)
        #expect(abs(km - 20.0) < 0.05)
    }

    @Test func dailyTarget_alreadyDone() {
        let (steps, km) = ProgressCalculator.dailyTarget(weeklyProgress: 1.0, remainingDays: 3)
        #expect(steps == 0)
        #expect(km == 0.0)
    }

    @Test func dailyTarget_noDaysLeft() {
        let (steps, km) = ProgressCalculator.dailyTarget(weeklyProgress: 0.5, remainingDays: 0)
        #expect(steps == 0)
        #expect(km == 0.0)
    }

    // MARK: - dailyTargetText

    @Test func dailyTargetText_thousands() {
        let text = ProgressCalculator.dailyTargetText(steps: 8_571, km: 5.7)
        #expect(text == "8.6k steps + 5.7km")
    }

    @Test func dailyTargetText_subThousand() {
        let text = ProgressCalculator.dailyTargetText(steps: 500, km: 0.3)
        #expect(text == "500 steps + 0.3km")
    }

    @Test func dailyTargetText_zero() {
        let text = ProgressCalculator.dailyTargetText(steps: 0, km: 0.0)
        #expect(text == "0 steps + 0.0km")
    }
}
