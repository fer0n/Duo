import SwiftUI

/// One-time introduction shown on the first launch.
struct WelcomeView: View {
    @Environment(ChallengeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isRequestingAccess = false

    private var weekdays: [(Int, String)] {
        let cal = Calendar.current
        let symbols = cal.weekdaySymbols  // localized, 0-indexed (0 = Sunday)
        let first = cal.firstWeekday - 1  // convert to 0-based index
        return (0..<7).map { offset in
            let idx = (first + offset) % 7
            return (idx + 1, symbols[idx])  // tag matches Calendar.weekday (1=Sunday…7=Saturday)
        }
    }

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    WelcomeRow(
                        symbol: Const.Symbol.steps,
                        title: "Your daily target, calculated",
                        message: """
                            Duo takes whatever is left of your weekly goal and splits it evenly \
                            across the days you have left. Steps and cycling count as alternatives, \
                            so any mix that adds up to 100% completes the day — and the week.
                            """
                    )

                    WelcomeRow(
                        symbol: "applewatch",
                        title: "Better on your wrist",
                        message: """
                            Install Duo on your Apple Watch and add a complication to your watch \
                            face to see how much of today's goal is left at a glance.
                            """
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("TK-Fit start day")
                                .font(.headline)
                            Spacer(minLength: 12)
                            Picker("TK-Fit start day", selection: $store.settings.challengeStartWeekday) {
                                ForEach(weekdays, id: \.0) { day in
                                    Text(day.1).tag(day.0)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .onChange(of: store.settings.challengeStartWeekday) { store.save() }
                        }
                        Text("You can change this any time in Settings.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .safeAreaBar(edge: .bottom) {
                Button {
                    isRequestingAccess = true
                    Task {
                        await store.requestHealthAccess()
                        dismiss()
                    }
                } label: {
                    ZStack {
                        Text("Grant Access to Health")
                            .fontWeight(.semibold)
                            .opacity(isRequestingAccess ? 0 : 1)
                        if isRequestingAccess {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRequestingAccess)
                .padding()
            }
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .task { await store.prewarmHealthKit() }
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: Const.Symbol.cycling)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.accentColor.gradient)

            Text("Welcome to Duo")
                .font(.largeTitle.bold())

            Text("""
                An unofficial companion for the TK-Fit Challenge — it tracks your progress \
                toward its weekly step and cycling goals.
                """)
                .foregroundStyle(.secondary)

            Link("About the TK-Fit Challenge", destination: Const.tkFitChallengeURL)
                .font(.subheadline.weight(.medium))
        }
    }
}

private struct WelcomeRow: View {
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color.accentColor.gradient)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environment(ChallengeStore())
}
