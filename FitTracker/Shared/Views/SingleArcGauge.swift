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

struct SingleArcGauge: View {
    var fraction: Double        // raw, unbounded (>1.0 = overflow/lap)
    var systemImage: String
    var color: Color = .accentColor
    var secondaryFraction: Double = 0   // combined context arc, drawn dimly behind

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = max(size * 0.14, 4)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: lineWidth)

                ArcShape(fraction: secondaryFraction)
                    .stroke(color.opacity(0.35),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                ArcShape(fraction: fraction)
                    .stroke(color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .shadow(color: .black, radius: 3)

                Image(systemName: systemImage)
                    .font(.system(size: size * 0.36, weight: .black))
            }
            .padding(lineWidth / 2)
            .frame(width: size, height: size)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .animation(.smooth, value: fraction)
        .animation(.smooth, value: secondaryFraction)
        .aspectRatio(1, contentMode: .fit)
    }
}
