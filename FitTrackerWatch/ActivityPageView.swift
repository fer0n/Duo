import SwiftUI

private let bikeColor = Color.accentColor.mix(with: .black, by: 0.2)

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
        VStack(spacing: 10) {
            ArcProgressBar(stepsFraction: config.stepsFraction, kmFraction: config.kmFraction, kmColor: bikeColor) {
                HStack {
                    Text(config.label)
                    Spacer()
                    Text(String(format: "%.1f%%", (config.stepsFraction + config.kmFraction) * 100))
                        .monospacedDigit()
                        .contentTransition(.numericText())

                }
            }
            .padding(.bottom, 5)

            ActivityRow(
                fraction: config.stepsFraction,
                systemImage: "figure.run",
                value: config.steps.formatted(),
                goal: "\(config.goalSteps.formatted()) steps",
                secondaryFraction: config.stepsFraction + config.kmFraction
            )

            ActivityRow(
                fraction: config.kmFraction,
                systemImage: "figure.outdoor.cycle",
                value: config.km.kmFormatted,
                goal: "\(config.goalKm.kmFormatted) km",
                secondaryFraction: config.stepsFraction + config.kmFraction
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    let store = ChallengeStore.preview()
    let weekly = store.weeklyStats
    NavigationStack {
        TabView {
            ActivityPageView(config: ActivityPageConfig(
                label: "Week",
                stepsFraction: weekly.stepsFraction,
                kmFraction: weekly.kmFraction,
                steps: weekly.steps,
                km: weekly.km,
                goalSteps: Int(ProgressCalculator.stepGoal),
                goalKm: ProgressCalculator.kmGoal
            ))
        }
        .tabViewStyle(.verticalPage)
    }
    .environment(store)
}
