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
    var fraction: Double    // clamped to 0...1 for display
    @ViewBuilder let label: Label

    private var clampedFraction: Double { min(max(fraction, 0), 1) }

    var body: some View {
        VStack(spacing: 2) {
            label

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.3))

                ProgressCapsule(fraction: clampedFraction)
                    .fill(Color.accentColor)
            }
            .animation(.smooth, value: clampedFraction)
            .frame(height: 8)
        }
        .font(.footnote)
        .fontWeight(.bold)
    }
}
