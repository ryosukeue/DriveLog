import UIKit

@MainActor
final class SystemPowerStateProvider: PowerStateProviding {
    nonisolated let changes: AsyncStream<PowerState>

    private let device: UIDevice
    private let center: NotificationCenter
    private let continuation: AsyncStream<PowerState>.Continuation
    private var observer: NSObjectProtocol?

    convenience init() {
        self.init(device: UIDevice.current, center: NotificationCenter.default)
    }

    init(device: UIDevice, center: NotificationCenter) {
        let stream = AsyncStream.makeStream(of: PowerState.self, bufferingPolicy: .bufferingNewest(1))
        changes = stream.stream
        continuation = stream.continuation
        self.device = device
        self.center = center
        device.isBatteryMonitoringEnabled = true
        observer = center.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.continuation.yield(self.current)
            }
        }
    }

    deinit {
        if let observer {
            center.removeObserver(observer)
        }
        continuation.finish()
    }

    var current: PowerState {
        switch device.batteryState {
        case .unknown: .unknown
        case .unplugged: .unplugged
        case .charging: .charging
        case .full: .full
        @unknown default: .unknown
        }
    }
}
