import SwiftUI

struct SettingsView: View {
    @Environment(ChallengeStore.self) private var store
    @State private var notificationsDenied = false

    private var anyNotificationEnabled: Bool {
        store.settings.notifyDailyGoal
            || store.settings.notifyWeeklyGoal
            || store.settings.dailyReminderEnabled
    }

    private var weekdays: [(Int, String)] {
        let cal = Calendar.current
        let symbols = cal.weekdaySymbols  // localized, 0-indexed (0 = Sunday)
        let first = cal.firstWeekday - 1  // convert to 0-based index
        return (0..<7).map { offset in
            let idx = (first + offset) % 7
            return (idx + 1, symbols[idx])  // tag matches Calendar.weekday (1=Sunday…7=Saturday)
        }
    }

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

    /// `store.save()` runs before the permission prompt is answered, so scheduling has to
    /// be retried once authorization is settled.
    private func enableNotifications() async {
        await NotificationManager.shared.requestAuthorization()
        notificationsDenied = await NotificationManager.shared.isDenied()
        await store.syncNotifications()
    }

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section {
                    Picker("Week starts on", selection: $store.settings.challengeStartWeekday) {
                        ForEach(weekdays, id: \.0) { day in
                            Text(day.1).tag(day.0)
                        }
                    }
                    .onChange(of: store.settings.challengeStartWeekday) { store.save() }
                }

                Section {
                    Toggle("Daily goal reached", isOn: $store.settings.notifyDailyGoal)
                        .onChange(of: store.settings.notifyDailyGoal) { _, enabled in
                            if enabled { Task { await enableNotifications() } }
                            store.save()
                        }
                    Toggle("Weekly goal reached", isOn: $store.settings.notifyWeeklyGoal)
                        .onChange(of: store.settings.notifyWeeklyGoal) { _, enabled in
                            if enabled { Task { await enableNotifications() } }
                            store.save()
                        }
                    Toggle("Remind if daily goal not reached", isOn: $store.settings.dailyReminderEnabled)
                        .onChange(of: store.settings.dailyReminderEnabled) { _, enabled in
                            if enabled { Task { await enableNotifications() } }
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
                } header: {
                    Text("Notifications")
                } footer: {
                    if notificationsDenied && anyNotificationEnabled {
                        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                            Label(
                                "Notifications are turned off for Fit — enable them in iOS Settings.",
                                systemImage: Const.Symbol.notificationsOff
                            )
                        }
                    }
                }
                .animation(.smooth, value: store.settings.dailyReminderEnabled)

                Section {
                    Stepper(
                        value: $store.settings.stepGoal,
                        in: 0...300_000,
                        step: 1_000,
                        onEditingChanged: { editing in if !editing { store.save() } },
                        label: {
                            LabeledContent("Steps", value: Int(store.settings.stepGoal).formatted())
                        }
                    )

                    Stepper(
                        value: $store.settings.kmGoal,
                        in: 0...500,
                        step: 1,
                        onEditingChanged: { editing in if !editing { store.save() } },
                        label: {
                            LabeledContent("Cycling", value: "\(store.settings.kmGoal.kmFormatted) km")
                        }
                    )
                } header: {
                    Text("Weekly Goals")
                } footer: {
                    Text("""
                        Steps and cycling count as alternatives — any mix that adds up to 100% \
                        completes the week. Set a goal to 0 to leave that activity out.
                        """)
                }

                Section {
                    Link(
                        "TK-Fit Challenge",
                        destination: URL(string: "https://www.tk.de/techniker/gesundheit-foerdern/"
                                            + "digitale-gesundheit/tk-fit/tk-fit-challenge-2077602")!
                    )
                } footer: {
                    Text("""
                        This app is an unofficial companion to the TK-Fit Challenge, helping you \
                        track your progress toward its weekly step and cycling goals.
                        """)
                }
            }
            .tint(.accentColor)
            .task { notificationsDenied = await NotificationManager.shared.isDenied() }
        }
    }
}

#Preview {
    SettingsView()
        .environment(ChallengeStore())
}
