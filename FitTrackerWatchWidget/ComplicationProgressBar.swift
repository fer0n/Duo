import SwiftUI

/// Steps and cycling share a single capsule: the cycling colour fills the whole
/// progress, the steps portion is painted over it, so only the outer ends round off.
struct ComplicationProgressBar: View {
    let stepsContrib: Double
    let cyclingContrib: Double

    private let barHeight: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let steps = min(max(stepsContrib, 0), 1)
            let total = min(steps + max(cyclingContrib, 0), 1)
            // Never narrower than the capsule is tall, or the fill collapses into a sliver.
            let fillWidth = total > 0 ? max(width * total, barHeight) : 0

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: barHeight)

                Capsule()
                    .fill(kmBarColor)
                    .frame(width: fillWidth, height: barHeight)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: width * steps)
                    }
                    .clipShape(Capsule())
            }
        }
        .frame(height: barHeight)
    }
}
