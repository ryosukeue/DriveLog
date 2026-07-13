import Foundation

nonisolated struct DistanceFormatter: Sendable {
    private let locale: Locale

    init(locale: Locale = .autoupdatingCurrent) {
        self.locale = locale
    }

    func kilometers(fromMeters distanceMeters: Double) -> String? {
        guard distanceMeters.isFinite, distanceMeters >= 0 else { return nil }
        let kilometers = distanceMeters / 1000
        let number = kilometers.formatted(
            .number
                .precision(.fractionLength(1))
                .locale(locale)
        )
        return "\(number)km"
    }
}
