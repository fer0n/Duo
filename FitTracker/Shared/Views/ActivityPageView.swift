import SwiftUI

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
    /// Widgets render a single static snapshot — they must not start from the empty state.
    var animates: Bool = true

    private struct DisplayState: Equatable {
        var stepsFraction: Double = 0
        var kmFraction: Double = 0
        var steps: Int = 0
        var km: Double = 0
    }

    @State private var animatedDisplay = DisplayState()

    private var current: DisplayState {
        DisplayState(stepsFraction: config.stepsFraction, kmFraction: config.kmFraction,
                     steps: config.steps, km: config.km)
    }

    private var display: DisplayState { animates ? animatedDisplay : current }

    var body: some View {
        VStack(spacing: 10) {
            ArcProgressBar(stepsFraction: display.stepsFraction, kmFraction: display.kmFraction, kmColor: kmBarColor) {
                HStack {
                    Text(config.label)
                    Spacer()
                    Text(String(format: "%.1f%%", (display.stepsFraction + display.kmFraction) * 100))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .padding(.bottom, 5)

            ActivityRow(
                fraction: display.stepsFraction,
                systemImage: "figure.run",
                value: display.steps.formatted(),
                goal: "\(config.goalSteps.formatted()) steps",
                secondaryFraction: display.stepsFraction + display.kmFraction
            )

            ActivityRow(
                fraction: display.kmFraction,
                systemImage: "figure.outdoor.cycle",
                value: display.km.kmFormatted,
                goal: "\(config.goalKm.kmFormatted) km",
                secondaryFraction: display.stepsFraction + display.kmFraction
            )
        }
        .onAppear {
            guard animates else { return }
            withAnimation(.smooth(duration: 1.5)) { animatedDisplay = current }
        }
        .onChange(of: current) { _, new in
            guard animates else { return }
            withAnimation(.smooth(duration: 1.5)) { animatedDisplay = new }
        }
    }
}
