import AppIntents

struct DailyRemainingResult: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Daily Remaining"

    @Property(title: "Remaining Steps")
    var remainingSteps: Int

    @Property(title: "Remaining Kilometers")
    var remainingKm: Double

    @Property(title: "Percentage Remaining")
    var percentageRemaining: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(percentageRemaining)% remaining",
            subtitle: "\(remainingSteps) steps · \(remainingKm, specifier: "%.1f") km"
        )
    }

    init() {
        remainingSteps = 0
        remainingKm = 0.0
        percentageRemaining = 0
    }

    init(remainingSteps: Int, remainingKm: Double, percentageRemaining: Int) {
        self.remainingSteps = remainingSteps
        self.remainingKm = remainingKm
        self.percentageRemaining = percentageRemaining
    }
}
