@MainActor
protocol PowerStateProviding: Sendable {
    var current: PowerState { get }
    nonisolated var changes: AsyncStream<PowerState> { get }
}

nonisolated enum PowerState: String, Sendable, Equatable {
    case unknown
    case unplugged
    case charging
    case full

    var locationRecordingMode: LocationRecordingMode {
        switch self {
        case .charging, .full:
            .chargingHighAccuracy
        case .unknown, .unplugged:
            .lowPower
        }
    }
}
