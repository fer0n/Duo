import SwiftUI

struct DataEntryView: View {
    @Environment(ChallengeStore.self) private var store
    @State private var steps: Int = 0
    @State private var km: Double = 0.0
    @State private var saved = false

    private var todayProgress: Double {
        ProgressCalculator.weeklyProgress(steps: steps, km: km)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Today's Activity") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Steps", systemImage: "figure.walk")
                            Spacer()
                            Text(steps.formatted())
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: Binding(
                            get: { Double(steps) },
                            set: { steps = Int($0) }
                        ), in: 0...60_000, step: 500)
                        .tint(.blue)
                        Stepper("", value: $steps, in: 0...100_000, step: 500)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Cycling", systemImage: "figure.outdoor.cycle")
                            Spacer()
                            Text(String(format: "%.1f km", km))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $km, in: 0...40, step: 0.5)
                            .tint(.green)
                        Stepper("", value: $km, in: 0...200, step: 0.5)
                            .labelsHidden()
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Today's contribution")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(todayProgress * 100))%")
                                .font(.subheadline.bold())
                        }
                        WeekProgressBar(
                            stepsContrib: ProgressCalculator.stepsContribution(steps: steps),
                            cyclingContrib: ProgressCalculator.cyclingContribution(km: km, steps: steps)
                        )
                    }
                } header: {
                    Text("Preview")
                }

                Section {
                    Button {
                        store.updateTodayEntry(steps: steps, km: km)
                        saved = true
                    } label: {
                        HStack {
                            Spacer()
                            let icon = saved ? "checkmark" : "square.and.arrow.down"
                            Label(saved ? "Saved!" : "Save Today", systemImage: icon)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(saved)
                }
            }
            .navigationTitle("Log Activity")
            .onAppear(perform: loadToday)
            .onChange(of: steps) { saved = false }
            .onChange(of: km) { saved = false }
        }
    }

    private func loadToday() {
        let entry = store.todayEntry()
        steps = entry.steps
        km = entry.cyclingKm
    }
}

#Preview {
    DataEntryView()
        .environment(ChallengeStore())
}
