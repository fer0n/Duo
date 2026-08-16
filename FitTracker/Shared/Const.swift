import Foundation

enum Const {
    static let tkFitChallengeURL = URL(
        string: "https://www.tk.de/techniker/gesundheit-foerdern/"
            + "digitale-gesundheit/tk-fit/tk-fit-challenge-2077602"
    )!

    enum Symbol {
        static let steps = "figure.run"
        static let cycling = "figure.outdoor.cycle"
        static let walking = "figure.walk"
        static let checkmark = "checkmark"
        static let calendar = "calendar"
        static let gear = "gear"
        static let notificationsOff = "bell.slash"
    }
}
