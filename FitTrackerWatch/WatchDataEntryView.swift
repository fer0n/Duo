import SwiftUI

struct WatchDataEntryView: View {
    @Environment(ChallengeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var steps: Int = 0
    @State private var km: Double = 0.0
    @State private var page = 0  // 0 = steps, 1 = km

    var body: some View {
        TabView(selection: $page) {
            stepsPage.tag(0)
            kmPage.tag(1)
            savePage.tag(2)
        }
        .tabViewStyle(.page)
        .onAppear {
            let entry = store.todayEntry()
            steps = entry.steps
            km = entry.cyclingKm
        }
        .navigationTitle("Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var stepsPage: some View {
        VStack(spacing: 6) {
            Label("Steps", systemImage: "figure.walk")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(steps.formatted())
                .font(.title3.bold())
                .monospacedDigit()
            HStack(spacing: 12) {
                Button { steps = max(0, steps - 500) } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                Button { steps = min(100_000, steps + 500) } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .controlSize(.small)
        }
        .focusable()
        .digitalCrownRotation(
            Binding(
                get: { Double(steps) },
                set: { steps = Int($0.rounded() / 500) * 500 }
            ),
            from: 0,
            through: 100_000,
            by: 500,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }

    private var kmPage: some View {
        VStack(spacing: 6) {
            Label("Cycling", systemImage: "figure.outdoor.cycle")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f km", km))
                .font(.title3.bold())
                .monospacedDigit()
            HStack(spacing: 12) {
                Button { km = max(0, km - 0.5) } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                Button { km = min(200, km + 0.5) } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .controlSize(.small)
        }
        .focusable()
        .digitalCrownRotation(
            $km,
            from: 0,
            through: 200,
            by: 0.5,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }

    private var savePage: some View {
        VStack(spacing: 8) {
            Text("\(steps.formatted()) steps")
                .font(.caption2)
            Text(String(format: "%.1f km", km))
                .font(.caption2)
            Button("Save") {
                store.updateTodayEntry(steps: steps, km: km)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
}

#Preview {
    NavigationStack {
        WatchDataEntryView()
    }
    .environment(ChallengeStore())
}
