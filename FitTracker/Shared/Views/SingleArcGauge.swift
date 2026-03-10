import SwiftUI

private struct ArcShape: Shape {
    var fraction: Double    // unbounded; >1.0 draws overlapping laps

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard fraction > 0 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        let fullLaps = Int(fraction)
        let remainder = fraction - Double(fullLaps)
        for _ in 0..<fullLaps {
            path.addArc(center: center, radius: radius,
                        startAngle: .degrees(-90), endAngle: .degrees(270), clockwise: false)
        }
        if remainder > 0 {
            path.addArc(center: center, radius: radius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * remainder),
                        clockwise: false)
        }
        return path
    }
}

let secondaryColor = Color.accentColor.mix(with: .black, by: 0.1).gradient

struct SingleArcGauge<Content: View>: View {
    var fraction: Double        // raw, unbounded (>1.0 = overflow/lap)
    var secondaryFraction: Double = 0   // combined context arc, drawn dimly behind
    @ViewBuilder var content: (CGFloat) -> Content

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = max(size * 0.15, 4)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.23), lineWidth: lineWidth)

                ArcShape(fraction: secondaryFraction)
                    .stroke(secondaryColor,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .shadow(color: .black.opacity(0.5), radius: 3)

                ArcShape(fraction: fraction)
                    .stroke(Color.accentColor.gradient,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .shadow(color: .black, radius: 3)

                content(size)
            }
            .padding(lineWidth / 2)
            .frame(width: size, height: size)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .animation(.smooth(duration: 2), value: fraction)
        .animation(.smooth(duration: 2), value: secondaryFraction)
        .aspectRatio(1, contentMode: .fit)
    }
}
