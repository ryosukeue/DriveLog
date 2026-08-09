import AVFoundation
import Observation

@MainActor
@Observable
final class AudioRouteVehicleDetector {
    private(set) var availableDevices: [AudioRouteDevice] = []
    private(set) var detectedVehicle: VehicleProfile?
    var onDetectedVehicleChange: ((VehicleProfile?) -> Void)?
    private var routeObserver: NSObjectProtocol?
    private let store: UserDefaultsVehicleStore
    private let notificationCenter: NotificationCenter
    private let session: AVAudioSession

    init(
        store: UserDefaultsVehicleStore,
        session: AVAudioSession = .sharedInstance(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.store = store
        self.session = session
        self.notificationCenter = notificationCenter
    }

    func start() {
        guard routeObserver == nil else {
            refresh()
            return
        }
        routeObserver = notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        refresh()
    }

    func refresh() {
        availableDevices = session.currentRoute.outputs
            .filter(Self.isVehicleCapableAudioRoute)
            .map {
                AudioRouteDevice(
                    uid: $0.uid,
                    name: $0.portName,
                    portType: $0.portType.rawValue
                )
            }
            .reduce(into: [AudioRouteDevice]()) { values, device in
                guard !values.contains(where: { $0.uid == device.uid }) else { return }
                values.append(device)
            }
        let detected = availableDevices.first { device in
            store.registeredVehicles().contains { $0.audioRouteUID == device.uid }
        }
        store.updateDetectedAudioRoute(uid: detected?.uid)
        let updatedVehicle = detected.flatMap { device in
            store.registeredVehicles().first { $0.audioRouteUID == device.uid }
        }
        guard updatedVehicle != detectedVehicle else { return }
        detectedVehicle = updatedVehicle
        onDetectedVehicleChange?(updatedVehicle)
    }

    private static func isVehicleCapableAudioRoute(
        _ port: AVAudioSessionPortDescription
    ) -> Bool {
        switch port.portType {
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .carAudio, .usbAudio:
            true
        default:
            false
        }
    }
}
