import SwiftUI

struct WatchStatView: View {
    let systemImage: String
    let value: String
    let goal: String

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Image(systemName: systemImage)
                .font(.title3)
                .fontWeight(.black)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3).monospacedDigit()
                    .fontWeight(.black)
                    .minimumScaleFactor(0.01)
                    .padding(.vertical, -4)
                    .contentTransition(.numericText())
                Text(goal)
                    .font(.caption).monospacedDigit()
                    .foregroundStyle(.secondary)
                    .fontWeight(.bold)
                    .padding(.vertical, -3)
            }
            .lineLimit(1)
        }
    }
}
