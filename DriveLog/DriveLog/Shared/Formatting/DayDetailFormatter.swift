import Foundation

nonisolated struct DayDetailFormatter: Sendable {
    private let timeZone: TimeZone
    private let distanceFormatter: DistanceFormatter

    init(
        timeZone: TimeZone,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.timeZone = timeZone
        distanceFormatter = DistanceFormatter(locale: locale)
    }

    func distance(meters: Double) -> String {
        distanceFormatter.kilometers(fromMeters: meters) ?? "--"
    }

    func duration(seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "--" }
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return hours > 0 ? "\(hours)時間 \(minutes)分" : "\(minutes)分"
    }

    func time(_ date: Date?) -> String {
        guard let date else { return "--" }
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.locale = Locale(identifier: "ja_JP")
        style.timeZone = timeZone
        return date.formatted(style)
    }

    func classification(_ value: AutomaticMovementType) -> String {
        switch value {
        case .automotiveLike:
            "車っぽい移動"
        case .walkingLike:
            "徒歩っぽい移動"
        case .other:
            "その他"
        }
    }
}
