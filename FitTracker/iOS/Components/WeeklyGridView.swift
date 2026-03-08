import SwiftUI

/// 7-cell grid showing each day of the current challenge week.
struct WeeklyGridView: View {
    let entries: [DailyEntry]
    let startWeekday: Int

    private let daySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    private var weekDates: [Date] {
        let weekStart = Calendar.current.currentWeekStart(startingOn: startWeekday)
        return (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: weekStart)
        }
    }

    private func entry(for date: Date) -> DailyEntry? {
        let key = DateFormatter.dayKey.string(from: date)
        return entries.first { $0.id == key }
    }

    private func color(for entry: DailyEntry?) -> Color {
        guard let entry, entry.steps > 0 || entry.cyclingKm > 0 else { return Color(.systemGray5) }
        if entry.steps > 0 && entry.cyclingKm > 0 { return .teal }
        if entry.steps > 0 { return .blue }
        return .green
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekDates, id: \.self) { date in
                let e = entry(for: date)
                VStack(spacing: 4) {
                    Circle()
                        .fill(color(for: e))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if let e, e.steps > 0 || e.cyclingKm > 0 {
                                Image(systemName: e.cyclingKm > 0 && e.steps == 0
                                        ? "figure.outdoor.cycle"
                                        : "figure.walk")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                            }
                        }
                    Text(dayLabel(for: date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func dayLabel(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return daySymbols[weekday - 1]
    }
}

private extension DateFormatter {
    static let dayKey: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

#Preview {
    WeeklyGridView(entries: [], startWeekday: 2)
        .padding()
}
