import SwiftUI

struct DailyTargetCard: View {
    let dailyTarget: (steps: Int, km: Double)
    let remainingDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Today's Target", systemImage: "target")
                .font(.headline)
            Text(ProgressCalculator.dailyTargetText(steps: dailyTarget.steps, km: dailyTarget.km))
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Text("\(remainingDays) day\(remainingDays == 1 ? "" : "s") remaining this week")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
