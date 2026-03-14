import SwiftUI
import Charts

let kmBarColor = Color.accentColor.mix(with: .black, by: 0.2)

struct HourlyChartView: View {
    let hourlyActivity: [HourlyActivity]

    private var maxUnits: Double { hourlyActivity.map(\.units).max() ?? 0 }
    private var minBar: Double { maxUnits > 0 ? maxUnits * 0.033 : 0.01 }

    var body: some View {
        Chart {
            // Total bar (steps + km) in km color — drawn first, behind.
            ForEach(hourlyActivity) { item in
                BarMark(
                    x: .value("Hour", item.date, unit: .hour),
                    y: .value("Activity", max(item.units, minBar)),
                    width: .ratio(0.7),
                    stacking: .unstacked
                )
                .clipShape(.capsule)
                .foregroundStyle(item.units > 0 ? kmBarColor : Color.secondary.opacity(0.25))
            }

            // Steps-only bar in accent color — overlaid on top, shorter.
            ForEach(hourlyActivity) { item in
                let stepsFraction = Double(item.steps) / ProgressCalculator.stepGoal
                BarMark(
                    x: .value("Hour", item.date, unit: .hour),
                    y: .value("Steps", stepsFraction > 0 ? max(stepsFraction, minBar) : 0),
                    width: .ratio(0.7),
                    stacking: .unstacked
                )
                .clipShape(.capsule)
                .foregroundStyle(stepsFraction > 0 ? Color.accentColor : Color.clear)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(Calendar.current.component(.hour, from: date), format: .number)
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(maxUnits > 0 ? maxUnits : 0.01))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
