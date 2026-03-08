import SwiftUI

private struct ProgressCapsule: Shape {
    var fraction: Double    // clamped to 0...1 before use

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let width = max(rect.height, CGFloat(fraction) * rect.width)
        return Capsule().path(in: CGRect(x: rect.minX, y: rect.minY,
                                         width: width, height: rect.height))
    }
}

struct ArcProgressBar<Label: View>: View {
    var stepsFraction: Double
    var kmFraction: Double = 0
    var kmColor: Color = .accentColor
    @ViewBuilder let label: Label

    private var clampedSteps: Double { min(max(stepsFraction, 0), 1) }
    private var clampedKm: Double { min(max(kmFraction, 0), 1) }
    private var clampedTotal: Double { min(clampedSteps + clampedKm, 1) }

    var body: some View {
        VStack(spacing: 4) {
            label

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.3))

                ProgressCapsule(fraction: clampedTotal)
                    .fill(kmColor)

                ProgressCapsule(fraction: clampedSteps)
                    .fill(Color.accentColor)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 3)
            }
            .animation(.smooth, value: clampedTotal)
            .animation(.smooth, value: clampedSteps)
            .frame(height: 20)
        }
        .font(.footnote)
        .fontWeight(.bold)
    }
}
