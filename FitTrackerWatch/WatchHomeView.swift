import SwiftUI

struct WatchHomeView: View {
    @Environment(ChallengeStore.self) private var store

    private var remainingFraction: Double { max(0, 1 - store.weeklyProgress) }
    private var remainingSteps: Int { Int((remainingFraction * ProgressCalculator.stepGoal).rounded()) }
    private var remainingKm: Double { remainingFraction * ProgressCalculator.kmGoal }

    private var remainingText: String {
        if store.weeklyProgress >= 1.0 { return "Weekly goal complete!" }
        let stepsK = Int((Double(remainingSteps) / 1000).rounded())
        let km = Int(remainingKm.rounded())
        return "\(stepsK)k steps or \(km)km left"
    }

    private var daysText: String {
        guard store.weeklyProgress < 1.0 else { return "" }
        return store.remainingDays == 1 ? "for the remaining day" : "for \(store.remainingDays) days"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 5) {
                Gauge(value: store.weeklyProgress, in: 0...1) {
                    Image(systemName: "figure.run")
                        .font(.caption2)
                } currentValueLabel: {
                    Text("\(Int(store.weeklyProgress * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .monospacedDigit()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(store.weeklyProgress >= 1.0 ? .green : .blue)
                .padding(.top, 4)

                Text(remainingText)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                if !daysText.isEmpty {
                    Text(daysText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

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
