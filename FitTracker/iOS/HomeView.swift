import SwiftUI

struct HomeView: View {
    @Environment(ChallengeStore.self) private var store

    private var dailyTarget: (steps: Int, km: Double) {
        ProgressCalculator.dailyTarget(
            weeklyProgress: store.weeklyProgress,
            remainingDays: store.remainingDays
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    progressRing
                    weekProgressSection
                    dailyTargetCard
                    weeklyGridSection
                }
                .padding()
            }
            .navigationTitle("FitChallenge")
        }
    }

    // MARK: - Subviews

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 16)
                .frame(width: 140, height: 140)

            Circle()
                .trim(from: 0, to: store.weeklyProgress)
                .stroke(
                    AngularGradient(colors: [.accentColor, .teal], center: .center),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 140, height: 140)
                .animation(.easeInOut, value: store.weeklyProgress)

            VStack(spacing: 2) {
                Text("\(Int(store.weeklyProgress * 100))%")
                    .font(.title2.bold())
                Text("this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var weekProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Weekly Progress", systemImage: "chart.bar.fill")
                    .font(.headline)
                Spacer()
                Text("\(store.weeklySteps.formatted()) steps · \(String(format: "%.1f", store.weeklyKm))km")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            WeekProgressBar(
                stepsContrib: ProgressCalculator.stepsContribution(steps: store.weeklySteps),
                cyclingContrib: ProgressCalculator.cyclingContribution(km: store.weeklyKm, steps: store.weeklySteps)
            )

            HStack(spacing: 16) {
                Label("Steps", systemImage: "circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.caption)
                Label("Cycling", systemImage: "circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dailyTargetCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Today's Target", systemImage: "target")
                .font(.headline)
            Text(ProgressCalculator.dailyTargetText(steps: dailyTarget.steps, km: dailyTarget.km))
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Text("\(store.remainingDays) day\(store.remainingDays == 1 ? "" : "s") remaining this week")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var weeklyGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("This Week", systemImage: "calendar")
                .font(.headline)
            WeeklyGridView(
                entries: store.currentWeekEntries(),
                startWeekday: store.settings.challengeStartWeekday
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .environment(ChallengeStore())
}
