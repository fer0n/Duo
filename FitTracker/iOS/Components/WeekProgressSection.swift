import SwiftUI

struct WeekProgressSection: View {
    let weeklySteps: Int
    let weeklyKm: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Weekly Progress", systemImage: "chart.bar.fill")
                    .font(.headline)
                Spacer()
                Text("\(weeklySteps.formatted()) steps · \(String(format: "%.1f", weeklyKm))km")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            WeekProgressBar(
                stepsContrib: ProgressCalculator.stepsContribution(steps: weeklySteps),
                cyclingContrib: ProgressCalculator.cyclingContribution(km: weeklyKm, steps: weeklySteps)
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
}
