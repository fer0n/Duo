import SwiftUI

/// Horizontal bar split into a blue (steps) segment and green (cycling) segment.
struct WeekProgressBar: View {
    let stepsContrib: Double    // 0...1, width fraction for steps
    let cyclingContrib: Double  // 0...1, width fraction for cycling (starts after steps)

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 16)

                if stepsContrib > 0 {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: width * stepsContrib, height: 16)
                }

                if cyclingContrib > 0 {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 8,
                        topTrailingRadius: 8
                    )
                    .fill(Color.green)
                    .frame(width: width * cyclingContrib, height: 16)
                    .offset(x: width * stepsContrib)
                }
            }
        }
        .frame(height: 16)
    }
}

#Preview {
    VStack(spacing: 12) {
        WeekProgressBar(stepsContrib: 0.4, cyclingContrib: 0.25)
        WeekProgressBar(stepsContrib: 0.7, cyclingContrib: 0.0)
        WeekProgressBar(stepsContrib: 0.0, cyclingContrib: 0.5)
        WeekProgressBar(stepsContrib: 0.0, cyclingContrib: 0.0)
    }
    .padding()
}
