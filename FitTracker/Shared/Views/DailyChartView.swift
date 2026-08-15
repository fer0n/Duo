import SwiftUI

struct DailyChartView: View {
    @Environment(ChallengeStore.self) private var store

    /// Optional binding so a host (e.g. iOS `HomeView`) can render the adaptive header itself.
    var headerLabel: Binding<String>?

    @State private var displayDays: [WeekDay] = []
    @State private var selectedDate: Date?

    private var chartModel: WeekChartModel {
        WeekChartModel(
            weekEntries: store.currentWeekEntries,
            startWeekday: store.settings.challengeStartWeekday,
            todaySteps: store.todaySteps,
            todayKm: store.todayKm
        )
    }

    private func day(for date: Date?, in days: [WeekDay]) -> WeekDay? {
        guard let date else { return nil }
        return days.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// Header text for the selected day's perspective, or the default projection label.
    private func headerText(selected: WeekDay?, model: WeekChartModel) -> String {
        guard let day = selected else { return model.headerLabel }
        guard day.goalLine > 0 else { return String(localized: "Daily") }
        let pct = day.total / day.goalLine * 100
        return String(localized: "\(pct.formatted(.number.precision(.fractionLength(0))))%")
    }

    var body: some View {
        let m = chartModel
        // When no future days remain, fall back to the last day's perspective so the
        // chart never shows an empty footer.
        let activeDate: Date? = selectedDate ?? (m.hasFutureDays ? nil : displayDays.last?.date)
        let selected = day(for: activeDate, in: displayDays)
        let header = headerText(selected: selected, model: m)

        VStack(spacing: 5) {
            WeekChart(
                days: displayDays,
                activeDate: activeDate,
                highlightNextDay: selected == nil && m.hasFutureDays,
                selection: $selectedDate
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 2)

            if let day = selected {
                HStack(spacing: 0) {
                    WatchStatView(
                        systemImage: Const.Symbol.steps,
                        value: day.steps.formatted(),
                        goal: day.goalSteps.formatted()
                    )
                    Spacer()
                        .frame(minWidth: 5, maxWidth: 8)
                    WatchStatView(
                        systemImage: Const.Symbol.cycling,
                        value: day.km.kmFormatted,
                        goal: day.goalKm.kmFormatted
                    )
                }
                .fontWidth(.condensed)
            } else if m.hasFutureDays && (m.projSteps > 0 || m.projKm > 0) {
                HStack(spacing: 0) {
                    WatchStatView(
                        systemImage: Const.Symbol.steps,
                        value: m.projSteps.formatted(),
                        goal: m.deltaSteps.formatted(.number.sign(strategy: .always()))
                    )
                    Spacer()
                        .frame(minWidth: 5, maxWidth: 8)
                    WatchStatView(
                        systemImage: Const.Symbol.cycling,
                        value: m.projKm.kmFormatted,
                        goal: m.deltaKm.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always()))
                    )
                }
                .fontWidth(.condensed)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { selectedDate = nil }  // tap outside the bars clears the selection
        #if os(watchOS)
        .navigationTitle(header)
        #endif
        .onChange(of: header, initial: true) { _, new in
            headerLabel?.wrappedValue = new
        }
        .onAppear {
            let days = m.days
            withAnimation(.smooth(duration: 1.0)) { displayDays = days }
        }
        .onChange(of: store.todaySteps) { _, _ in
            let days = chartModel.days
            withAnimation(.smooth(duration: 1.0)) { displayDays = days }
        }
    }
}

#if os(watchOS) && DEBUG
#Preview {
    @Previewable @State var scenarioIndex = 0

    let store = ChallengeStore.preview(
        steps: ChallengeStore.previewScenarios[0].steps,
        km: ChallengeStore.previewScenarios[0].km
    )
    let todayKey = Date.todayKey()

    NavigationStack {
        TabView {
            DailyChartView()
        }
        .tabViewStyle(.verticalPage)
    }
    .environment(store)
    .task(id: scenarioIndex) {
        let s = ChallengeStore.previewScenarios[scenarioIndex]
        withAnimation(.smooth) {
            store.entries[todayKey] = DailyEntry(id: todayKey, steps: s.steps, cyclingKm: s.km, date: .now)
        }
    }
    .overlay(alignment: .top) {
        Button {
            scenarioIndex = (scenarioIndex + 1) % ChallengeStore.previewScenarios.count
        } label: {
            Text("\(scenarioIndex + 1)/\(ChallengeStore.previewScenarios.count)")
                .font(.system(size: 9, weight: .bold))
                .padding(4)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, -40)
        .padding(.bottom, 2)
    }
}
#endif
