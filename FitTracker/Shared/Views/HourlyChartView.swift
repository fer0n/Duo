import SwiftUI
import Charts

let kmBarColor = Color.accentColor.mix(with: .black, by: 0.2)

struct HourlyChartView: View {
    let hourlyActivity: [HourlyActivity]

    private var maxUnits: Double { hourlyActivity.map(\.units).max() ?? 0 }
    private var minBar: Double { maxUnits > 0 ? maxUnits * 0.033 : 0.01 }
    let ratio: Double = 0.65

    var body: some View {
        Chart {
            // Total bar (steps + km) in km color — drawn first, behind.
            ForEach(hourlyActivity) { item in
                BarMark(
                    x: .value("Hour", item.date, unit: .hour),
                    y: .value("Activity", max(item.units, minBar)),
                    width: .ratio(ratio),
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
                    width: .ratio(ratio),
                    stacking: .unstacked
                )
                .clipShape(.capsule)
                .foregroundStyle(stepsFraction > 0 ? Color.accentColor : Color.clear)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisTick()
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(Calendar.current.component(.hour, from: date), format: .number)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(maxUnits > 0 ? maxUnits : 0.01))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let hourlySteps = [0, 0, 0, 0, 0, 0, 80, 950, 1200, 400, 300, 200,
                       750, 600, 150, 200, 180, 300, 1100, 800, 400, 100, 50, 0]
    let hourlyKm: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 3.2, 4.1, 7.8, 0, 0, 0, 0]
    let mockData = (0..<24).map { HourlyActivity(hour: $0, steps: hourlySteps[$0], km: hourlyKm[$0]) }

    NavigationStack {
        TabView {
            HourlyChartView(hourlyActivity: mockData)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Hourly")
        }
        #if os(watchOS)
        .tabViewStyle(.verticalPage)
        #endif
    }
}
