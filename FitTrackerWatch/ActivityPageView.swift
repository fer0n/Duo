import SwiftUI

struct ActivityPageConfig {
    var label: String
    var stepsFraction: Double
    var kmFraction: Double
    var steps: Int
    var km: Double
    var goalSteps: Int
    var goalKm: Double
    var secondaryBar: (label: String, fraction: Double)?
}

struct ActivityPageView: View {
    let config: ActivityPageConfig

    var body: some View {
        VStack(spacing: 7) {
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
                goal: String(format: "%.1f km", config.goalKm)
            )

            ArcProgressBar(fraction: config.stepsFraction + config.kmFraction) {
                HStack {
                    Text(config.label)
                    Spacer()
                    Text(String(format: "%.1f%%", (config.stepsFraction + config.kmFraction) * 100))
                }
            }

            if let secondary = config.secondaryBar {
                ArcProgressBar(fraction: secondary.fraction) {
                    HStack {
                        Text(secondary.label)
                        Spacer()
                        Text(String(format: "%.1f%%", secondary.fraction * 100))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
