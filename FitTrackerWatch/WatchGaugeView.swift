import SwiftUI

struct WatchGaugeView: View {
    let stepsFraction: Double
    let kmFraction: Double
    let todaySteps: Int
    let todayKm: Double
    let goalSteps: Int
    let goalKm: Double
    let isWeeklyGoalReached: Bool

    private var goalFraction: Double {
        stepsFraction + kmFraction
    }

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            SingleArcGauge(fraction: stepsFraction, secondaryFraction: kmFraction + stepsFraction) { size in
                ZStack {
                    if isWeeklyGoalReached {
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.25, weight: .black))
                            .foregroundStyle(Color.accentColor.gradient)
                            .transition(.blurReplace)
                    } else {
                        Text(Int(goalFraction * 100).formatted())
                            .font(.largeTitle)
                            .monospacedDigit()
                            .fontWidth(.compressed)
                            .fontWeight(.black)
                            .foregroundStyle(Color.accentColor.gradient)
                            .contentTransition(.numericText())
                            .transition(.blurReplace)
                    }
                }
            }
            .animation(.smooth.speed(0.4), value: isWeeklyGoalReached)
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
                    value: todayKm.kmFormatted,
                    goal: goalKm.kmFormatted
                )
            }
            .fontWidth(.condensed)
            .animation(.smooth(duration: 1.5), value: todaySteps)
            .animation(.smooth(duration: 1.5), value: todayKm)
        }
        .padding(.vertical, -12)
    }
}

#Preview {
    @Previewable @State var scenarioIndex = 0
    @Previewable @State var store = ChallengeStore.preview(
        steps: ChallengeStore.previewDoneScenarios[0].steps,
        km: ChallengeStore.previewDoneScenarios[0].km
    )
    let todayKey = Date.todayKey()
    let daily = store.dailyContext

    NavigationStack {
        TabView {
            WatchGaugeView(
                stepsFraction: daily.stepsFraction,
                kmFraction: daily.kmFraction,
                todaySteps: store.todaySteps,
                todayKm: store.todayKm,
                goalSteps: daily.goalSteps,
                goalKm: daily.goalKm,
                isWeeklyGoalReached: store.weeklyStats.progress >= 1.0
            )
        }
        .tabViewStyle(.verticalPage)
    }
    .task(id: scenarioIndex) {
        let s = ChallengeStore.previewDoneScenarios[scenarioIndex]
        withAnimation(.smooth) {
            store.entries[todayKey] = DailyEntry(id: todayKey, steps: s.steps, cyclingKm: s.km, date: .now)
        }
    }
    .overlay(alignment: .top) {
        Button {
            scenarioIndex = (scenarioIndex + 1) % ChallengeStore.previewDoneScenarios.count
        } label: {
            Text("\(scenarioIndex + 1)/\(ChallengeStore.previewDoneScenarios.count)")
                .font(.system(size: 9, weight: .bold))
                .padding(4)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, -40)
        .padding(.bottom, 2)
    }
}
