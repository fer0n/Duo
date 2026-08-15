import SwiftUI

struct WeeklyGridSection: View {
    let entries: [DailyEntry]
    let startWeekday: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("This Week", systemImage: Const.Symbol.calendar)
                .font(.headline)
            WeeklyGridView(entries: entries, startWeekday: startWeekday)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
