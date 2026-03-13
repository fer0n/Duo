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

    private var rawSteps: Double { max(stepsFraction, 0) }
    private var rawTotal: Double { max(stepsFraction + kmFraction, 0) }
    private var scale: Double { max(1.0, rawTotal) }
    private var scaledTotal: Double { rawTotal / scale }
    private var scaledSteps: Double { rawSteps / scale }

    var body: some View {
        VStack(spacing: 2) {
            label

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))

                ProgressCapsule(fraction: scaledTotal)
                    .fill(kmColor)
                    .shadow(color: .black.opacity(0.4), radius: 3)

                ProgressCapsule(fraction: scaledSteps)
                    .fill(Color.accentColor)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.4), radius: 3)
            }
            .frame(height: 20)
        }
        .font(.footnote)
        .fontWeight(.bold)
    }
}
