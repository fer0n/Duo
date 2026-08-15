import WidgetKit

/// The weekly bar chart needs the whole week, which the other complications don't.
struct WeekChartEntry: TimelineEntry {
    let date: Date
    let days: [WeekDay]
    let header: String
    /// What tomorrow asks for, or nil on the last day of the week.
    let nextTarget: (steps: Int, km: Double)?
}

struct WeekChartProvider: TimelineProvider {
    typealias Entry = WeekChartEntry

    private func makeEntry(date: Date, model: WeekChartModel) -> WeekChartEntry {
        let next = model.days.first(where: \.isNextDay)
        let target: (steps: Int, km: Double)? = next.flatMap {
            $0.goalSteps > 0 || $0.goalKm > 0 ? ($0.goalSteps, $0.goalKm) : nil
        }
        return WeekChartEntry(
            date: date,
            days: model.days,
            header: model.headerLabel,
            nextTarget: target
        )
    }

    func placeholder(in context: Context) -> WeekChartEntry {
        makeEntry(date: .now, model: WeekChartSampleData.model)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekChartEntry) -> Void) {
        let model = context.isPreview
            ? WeekChartSampleData.model
            : WeekChartModel(snapshot: ChallengeSnapshot())
        completion(makeEntry(date: .now, model: model))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekChartEntry>) -> Void) {
        let entry = makeEntry(date: .now, model: WeekChartModel(snapshot: ChallengeSnapshot()))
        // Refresh at the top of the next hour
        let nextUpdate = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date(timeIntervalSinceNow: 3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}
