import SwiftUI
import Charts

struct WatchHourlyView: View {
    let hourlyActivity: [HourlyActivity]

    private var maxUnits: Double { hourlyActivity.map(\.units).max() ?? 0 }
    private var minBar: Double { maxUnits > 0 ? maxUnits * 0.04 : 0.01 }

    var body: some View {
        Chart(hourlyActivity) { item in
            let displayValue = max(item.units, minBar)
            BarMark(
                x: .value("Hour", item.hour),
                y: .value("Activity", displayValue),
                width: .inset(2.5)
            )
            .clipShape(.capsule)
            .foregroundStyle(
                item.units > 0
                    ? Color.accentColor
                    : Color.secondary.opacity(0.25)
            )
        }
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text("\(hour)")
                            .font(.system(size: 7))
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(maxUnits > 0 ? maxUnits * 1.2 : 0.01))
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
