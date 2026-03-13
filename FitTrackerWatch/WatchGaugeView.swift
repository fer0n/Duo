import SwiftUI

struct WatchGaugeView: View {
    let stepsFraction: Double
    let kmFraction: Double
    let todaySteps: Int
    let todayKm: Double
    let goalSteps: Int
    let goalKm: Double

    private var isGoalReached: Bool {
        stepsFraction + kmFraction >= 1.0
    }

    private var goalFraction: Double {
        min(stepsFraction + kmFraction, 1.0)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            SingleArcGauge(fraction: stepsFraction, secondaryFraction: kmFraction + stepsFraction) { size in
                ZStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.25, weight: .black))
                        .scaleEffect(isGoalReached ? 1 : 0.3)
                        .opacity(isGoalReached ? 1 : 0)
                        .animation(.smooth, value: isGoalReached)

                    Text(Int(goalFraction * 100).formatted())
                        .font(.largeTitle)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .opacity(isGoalReached ? 0 : 1)
                        .fontWidth(.compressed)
                        .fontWeight(.black)
                }
                .foregroundStyle(Color.accentColor.gradient)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                WatchStatView(
                    systemImage: "figure.run",
                    value: todaySteps.formatted(),
                    goal: goalSteps.formatted()
                )
                Spacer()
                    .frame(minWidth: 5, maxWidth: 8)
                WatchStatView(
                    systemImage: "figure.outdoor.cycle",
                    value: todayKm.formatted(),
                    goal: goalKm.formatted()
                )
            }
            .fontWidth(.condensed)
            .animation(.smooth(duration: 1.5), value: todaySteps)
            .animation(.smooth(duration: 1.5), value: todayKm)
        }
        .padding(.vertical, -10)
    }
}
