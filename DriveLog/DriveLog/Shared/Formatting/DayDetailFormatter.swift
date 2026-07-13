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

    func classification(_ value: UserMovementClassification?) -> String {
        switch value {
        case .automotive:
            "車"
        case .train:
            "電車"
        case .bus:
            "バス"
        case .walking:
            "徒歩"
        case .other:
            "その他"
        case nil:
            "未設定"
        }
    }

    func averageSpeed(metersPerSecond: Double?) -> String {
        guard let metersPerSecond,
              metersPerSecond.isFinite,
              metersPerSecond >= 0
        else { return "--" }
        let kilometersPerHour = metersPerSecond * 3.6
        return String(format: "%.1fkm/h", kilometersPerHour)
    }

    func stayConfidence(_ value: StayConfidence) -> String {
        switch value {
        case .low:
            "低"
        case .medium:
            "中"
        case .high:
            "高"
        }
    }
}
