import SwiftUI

private let bikeColor = Color.accentColor.mix(with: .black, by: 0.25)

struct ActivityPageConfig {
    var label: String
    var stepsFraction: Double
    var kmFraction: Double
    var steps: Int
    var km: Double
    var goalSteps: Int
    var goalKm: Double
    var secondaryBar: (label: String, stepsFraction: Double, kmFraction: Double)?
}

struct ActivityPageView: View {
    let config: ActivityPageConfig

    var body: some View {
        VStack(spacing: 15) {
            ActivityRow(
                fraction: config.stepsFraction,
                systemImage: "figure.run",
                value: config.steps.formatted(),
                goal: "\(config.goalSteps.formatted()) steps"
            )

            ActivityRow(
                fraction: config.kmFraction,
                systemImage: "figure.outdoor.cycle",
                value: String(format: "%.1f", config.km),
                goal: String(format: "%.1f km", config.goalKm),
                color: bikeColor
            )

            ArcProgressBar(stepsFraction: config.stepsFraction, kmFraction: config.kmFraction, kmColor: bikeColor) {
                HStack {
                    Text(config.label)
                    Spacer()
                    Text(String(format: "%.1f%%", (config.stepsFraction + config.kmFraction) * 100))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
