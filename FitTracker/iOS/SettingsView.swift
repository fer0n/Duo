import SwiftUI

struct SettingsView: View {
    @Environment(ChallengeStore.self) private var store

    private let weekdays: [(Int, String)] = [
        (1, "Sunday"), (2, "Monday"), (3, "Tuesday"),
        (4, "Wednesday"), (5, "Thursday"), (6, "Friday"), (7, "Saturday")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Challenge Week Start") {
                    Picker("Week starts on", selection: Binding(
                        get: { store.settings.challengeStartWeekday },
                        set: {
                            store.settings.challengeStartWeekday = $0
                            store.save()
                        }
                    )) {
                        ForEach(weekdays, id: \.0) { day in
                            Text(day.1).tag(day.0)
                        }
                    }
                }

                Section("Weekly Goals") {
                    LabeledContent("Steps goal", value: "60,000 steps")
                    LabeledContent("Cycling goal", value: "40 km")
                    LabeledContent("Formula", value: "steps÷60k + km÷40 = 100%")
                }

                Section("About") {
                    LabeledContent("TK Fit Challenge", value: "2025")
                    // swiftlint:disable:next line_length
                    Link("Challenge Info", destination: URL(string: "https://www.tk.de/techniker/gesundheit-foerdern/digitale-gesundheit/spezial/tk-fit/tk-fit-challenge-2077602")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environment(ChallengeStore())
}
