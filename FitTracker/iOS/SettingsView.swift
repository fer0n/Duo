import SwiftUI

struct SettingsView: View {
    @Environment(ChallengeStore.self) private var store

    private let weekdays: [(Int, String)] = [
        (1, "Sunday"), (2, "Monday"), (3, "Tuesday"),
        (4, "Wednesday"), (5, "Thursday"), (6, "Friday"), (7, "Saturday")
    ]

    private func reminderTimeBinding(store: ChallengeStore) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: store.settings.dailyReminderHour,
                    minute: store.settings.dailyReminderMinute,
                    second: 0, of: .now
                ) ?? .now
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.settings.dailyReminderHour = comps.hour ?? 20
                store.settings.dailyReminderMinute = comps.minute ?? 0
                store.save()
            }
        )
    }

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section("Challenge Week Start") {
                    Picker("Week starts on", selection: $store.settings.challengeStartWeekday) {
                        ForEach(weekdays, id: \.0) { day in
                            Text(day.1).tag(day.0)
                        }
                    }
                    .onChange(of: store.settings.challengeStartWeekday) { store.save() }
                }

                Section("Notifications") {
                    Toggle("Daily goal reached", isOn: $store.settings.notifyDailyGoal)
                        .onChange(of: store.settings.notifyDailyGoal) { _, enabled in
                            if enabled {
                                Task { await NotificationManager.shared.requestAuthorization() }
                            }
                            store.save()
                        }
                    Toggle("Weekly goal reached", isOn: $store.settings.notifyWeeklyGoal)
                        .onChange(of: store.settings.notifyWeeklyGoal) { _, enabled in
                            if enabled {
                                Task { await NotificationManager.shared.requestAuthorization() }
                            }
                            store.save()
                        }
                    Toggle("Remind if daily goal not reached", isOn: $store.settings.dailyReminderEnabled)
                        .onChange(of: store.settings.dailyReminderEnabled) { _, enabled in
                            if enabled {
                                Task { await NotificationManager.shared.requestAuthorization() }
                            }
                            store.save()
                        }
                    if store.settings.dailyReminderEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: reminderTimeBinding(store: store),
                            displayedComponents: .hourAndMinute
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.smooth, value: store.settings.dailyReminderEnabled)

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
