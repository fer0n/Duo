import SwiftUI

struct WatchHomeView: View {
    @Environment(ChallengeStore.self) private var store

    private var dailyTarget: (steps: Int, km: Double) {
        ProgressCalculator.dailyTarget(
            weeklyProgress: store.weeklyProgress,
            remainingDays: store.remainingDays
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Gauge(value: store.weeklyProgress, in: 0...1) {
                    Image(systemName: "figure.run")
                        .font(.caption2)
                } currentValueLabel: {
                    Text("\(Int(store.weeklyProgress * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .monospacedDigit()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(
                    store.weeklyProgress >= 1.0 ? .green : .blue
                )
                .scaleEffect(1.3)
                .padding(.top, 4)

                Text(ProgressCalculator.dailyTargetText(
                    steps: dailyTarget.steps,
                    km: dailyTarget.km
                ))
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

                Text("\(store.remainingDays)d left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                NavigationLink("Log Activity") {
                    WatchDataEntryView()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("FitChallenge")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WatchHomeView()
    }
    .environment(ChallengeStore())
}
