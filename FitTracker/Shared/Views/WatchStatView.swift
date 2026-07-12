import SwiftUI

struct WatchStatView: View {
    let systemImage: String
    let value: String
    let goal: String

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Image(systemName: systemImage)
                #if os(watchOS)
                .font(.title3)
                #else
                .font(.title2)
                #endif
                .fontWeight(.black)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    #if os(watchOS)
                    .font(.title3).monospacedDigit()
                    #else
                    .font(.title2).monospacedDigit()
                    #endif
                    .fontWeight(.black)
                    .minimumScaleFactor(0.01)
                    .padding(.vertical, -3)
                    .contentTransition(.numericText())
                Text(goal)
                    #if os(watchOS)
                    .font(.caption).monospacedDigit()
                    #else
                    .font(.footnote).monospacedDigit()
                    #endif
                    .foregroundStyle(.secondary)
                    .fontWeight(.bold)
                    .padding(.vertical, -3)
            }
            .lineLimit(1)
        }
    }
}

#Preview {
    WatchStatView(systemImage: "figure.run", value: "4,200", goal: "10,000")
}
