import Foundation

struct DailyEntry: Codable, Identifiable {
    var id: String  // "yyyy-MM-dd"
    var steps: Int
    var cyclingKm: Double
    var date: Date
}
