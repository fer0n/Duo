import Foundation

struct ChallengeSettings: Codable {
    // 1=Sunday, 2=Monday, ... 7=Saturday (matches Calendar.weekday)
    var challengeStartWeekday: Int = 2  // Monday default
}
