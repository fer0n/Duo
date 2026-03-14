import Foundation

extension Double {
    var kmFormatted: String { formatted(.number.precision(.fractionLength(0...1))) }
}
