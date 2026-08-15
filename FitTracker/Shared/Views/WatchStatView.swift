import SwiftUI

struct WatchStatView: View {
    let systemImage: String
    let value: String
    let goal: String
    /// Tighter type for small widgets, where two stats share very little width.
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Image(systemName: systemImage)
                #if os(watchOS)
                .font(.title3)
                #else
                .font(compact ? .subheadline : .title2)
                #endif
                .fontWeight(.black)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    #if os(watchOS)
                    .font(.title3).monospacedDigit()
                    #else
                    .font(compact ? .subheadline : .title2).monospacedDigit()
                    #endif
                    .fontWeight(.black)
                    .minimumScaleFactor(0.01)
                    .padding(.vertical, -3)
                    .contentTransition(.numericText())
                Text(goal)
                    #if os(watchOS)
                    .font(.caption).monospacedDigit()
                    #else
                    .font(compact ? .caption2 : .footnote).monospacedDigit()
                    #endif
                    .foregroundStyle(.secondary)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.5)  // narrow widgets would otherwise clip the goal
                    .padding(.vertical, -3)
            }
            .lineLimit(1)
        }
    }
}

#Preview {
    WatchStatView(systemImage: Const.Symbol.steps, value: "4,200", goal: "10,000")
}
