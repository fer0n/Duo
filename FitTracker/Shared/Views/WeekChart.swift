import SwiftUI
import Charts

/// The weekly bar chart itself: one bar per day (total + steps portion) plus the
/// dashed goal line. Presentational only — hosts supply the days and own any selection.
struct WeekChart: View {
    let days: [WeekDay]
    /// Day the user is inspecting; every other day is dimmed.
    var activeDate: Date?
    /// Rings the goal dot of tomorrow when nothing is selected.
    var highlightNextDay: Bool = false
    var selection: Binding<Date?>?
    /// Thinner bars, smaller labels and dots so the chart still reads in a complication.
    var compact: Bool = false

    /// Matches the background behind the chart so the highlight marker can paint over the goal line.
    private var chartMaskColor: Color {
        #if os(watchOS)
        .black
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    private var barWidth: CGFloat { compact ? 6 : 14 }
    private var goalDotSize: CGFloat { compact ? 16 : 30 }

    private var maxValue: Double {
        max(days.map(\.total).max() ?? 0, days.map(\.goalLine).max() ?? 0)
    }

    private func barDisplay(_ value: Double, min minFraction: Double) -> Double {
        value == 0 ? 0 : max(value, minFraction)
    }

    private func barGradient(value: Double, display: Double, color: Color) -> LinearGradient {
        let clearStop = display > 0 ? max(0.0, 1.0 - value / display) : 0.0
        return LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: clearStop),
                .init(color: color, location: clearStop),
                .init(color: color, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// A day is dimmed to grayscale when another day is the active one.
    private func isDimmed(_ day: WeekDay) -> Bool {
        guard let activeDate else { return false }
        return !Calendar.current.isDate(day.date, inSameDayAs: activeDate)
    }

    var body: some View {
        let maxVal = maxValue
        let minBarFraction = maxVal * 0.07

        Chart {
            ForEach(days) { day in
                let display = day.isFuture ? 0.0 : barDisplay(day.total, min: minBarFraction)
                let dimmed = isDimmed(day)
                let color: Color = dimmed
                    ? .secondary.opacity(0.35)
                    : (day.isFuture ? .secondary.opacity(0.15) : kmBarColor)
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Total", display),
                    width: .fixed(barWidth),
                    stacking: .unstacked
                )
                .clipShape(.capsule)
                .foregroundStyle(barGradient(value: day.total, display: display, color: color))
            }

            ForEach(days) { day in
                let display = day.isFuture ? 0.0 : barDisplay(day.stepsFraction, min: minBarFraction)
                let color: Color = isDimmed(day) ? .secondary.opacity(0.7) : .accentColor
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Steps", display),
                    width: .fixed(barWidth),
                    stacking: .unstacked
                )
                .clipShape(.capsule)
                .foregroundStyle(barGradient(value: day.stepsFraction, display: display, color: color))
            }

            ForEach(days) { day in
                let isNextDayHighlight = highlightNextDay && day.isNextDay

                LineMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Goal", day.goalLine)
                )
                .lineStyle(StrokeStyle(lineWidth: compact ? 1 : 1.5, dash: compact ? [3, 2] : [4, 3]))
                .foregroundStyle(Color.primary.opacity(0.5))

                PointMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Goal", day.goalLine)
                )
                .symbolSize(goalDotSize)
                .foregroundStyle(
                    isNextDayHighlight
                        ? AnyShapeStyle(Color.accentColor)
                        : AnyShapeStyle(Color.primary.opacity(0.8))
                )
                .annotation(position: .overlay) {
                    // The ring needs an opaque disc behind it, which a complication
                    // has no background to match — there the plain dot stands in.
                    if isNextDayHighlight && !compact {
                        ZStack {
                            // Paints over the dashed goal line so it never shows
                            // through the gap between the inner dot and the ring.
                            Circle()
                                .fill(chartMaskColor)
                                .frame(width: 10, height: 10)
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 5, height: 5)
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 1.5)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(maxVal > 0 ? maxVal * 1 : 0.02))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(centered: true) {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.weekday(.narrow))
                            .font(compact ? .system(size: 9) : .footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                Calendar.current.isDateInToday(date) ? Color.accentColor : Color.secondary
                            )
                    }
                }
            }
        }
        .chartXSelection(value: selection ?? .constant(nil))
    }
}
