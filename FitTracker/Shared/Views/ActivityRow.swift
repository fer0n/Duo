import SwiftUI

struct ActivityRow: View {
    var fraction: Double
    var systemImage: String
    var value: String
    var goal: String
    var secondaryFraction: Double = 0

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            SingleArcGauge(fraction: fraction, secondaryFraction: secondaryFraction) { size in
                Image(systemName: systemImage)
                    .font(.system(size: size * 0.33, weight: .black))
            }
            .frame(width: 45, height: 45)

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text(value)
                    .font(.title).monospacedDigit()
                    .minimumScaleFactor(0.01)
                    .lineLimit(1)
                    .padding(.vertical, -7)
                    .contentTransition(.numericText())

                Text(goal)
                    .font(.footnote).monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .fontWeight(.bold)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
