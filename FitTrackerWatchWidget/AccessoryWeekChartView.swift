import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

/// The weekly bar chart needs the whole week, which the other complications don't.
struct WeekChartEntry: TimelineEntry {
    let date: Date
    let days: [WeekDay]
    let header: String
    /// What tomorrow asks for, or nil on the last day of the week.
    let nextTarget: (steps: Int, km: Double)?
}

// MARK: - Timeline Provider

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

// MARK: - View

/// The weekly bar chart from the watch app's second page, shrunk to a complication:
/// header, tomorrow's target, and one bar per day against the dashed goal line.
struct AccessoryWeekChartView: View {
    let entry: WeekChartEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(entry.header)
                Spacer(minLength: 0)
                if let target = entry.nextTarget {
                    Text(ProgressCalculator.stepsText(target.steps))
                        .foregroundStyle(Color.accentColor)
                        .widgetAccentable()

                    Text("\(target.km.kmFormatted) km")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 13, weight: .bold))
            .monospacedDigit()
            .fontWidth(.condensed)
            .lineLimit(1)
            // No minimumScaleFactor: it scales each Text on its own, which left the
            // header label smaller than the numbers next to it.

            WeekChart(
                days: entry.days,
                highlightNextDay: true,
                compact: true
            )
        }
        .widgetURL(URL(string: "fittracker://open"))
    }
}

// MARK: - Sample Data

/// Stand-in week for placeholders and previews, so neither touches real data.
enum WeekChartSampleData {
    static let todaySteps = 4_200
    static let todayKm = 2.6

    static var model: WeekChartModel {
        let cal = Calendar.current
        let startWeekday = ChallengeSettings().challengeStartWeekday
        let weekStart = cal.currentWeekStart(startingOn: startWeekday)
        let pastDays: [(steps: Int, km: Double)] = [
            (8_500, 1.3), (6_200, 1.3), (9_100, 0),
            (1_200, 0), (500, 1.0), (4_300, 6.0)
        ]
        let todayIndex = max(0, min(
            cal.dateComponents([.day], from: weekStart, to: cal.startOfDay(for: .now)).day ?? 0, 6
        ))

        var entries: [DailyEntry] = (0..<todayIndex).map { i in
            let date = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
            let day = pastDays[i % pastDays.count]
            return DailyEntry(id: "sample-\(i)", steps: day.steps, cyclingKm: day.km, date: date)
        }
        entries.append(DailyEntry(id: Date.todayKey(), steps: todaySteps, cyclingKm: todayKm, date: .now))

        return WeekChartModel(
            weekEntries: entries,
            startWeekday: startWeekday,
            todaySteps: todaySteps,
            todayKm: todayKm
        )
    }
}

#Preview(as: .accessoryRectangular) {
    FitChallengeWeekChartWidget()
} timeline: {
    let model = WeekChartSampleData.model
    let next = model.days.first(where: \.isNextDay)
    WeekChartEntry(
        date: .now,
        days: model.days,
        header: model.headerLabel,
        nextTarget: next.map { ($0.goalSteps, $0.goalKm) }
    )
}
