import CoreLocation
import CoreMotion
import Foundation
import Photos
import UIKit

@MainActor
protocol PermissionSystemAccessing: AnyObject {
    var locationStatus: CLAuthorizationStatus { get }
    var motionStatus: CMAuthorizationStatus { get }
    var photoStatus: PHAuthorizationStatus { get }
    var authorizationChanges: AsyncStream<Void> { get }

    func requestLocationWhenInUse()
    func requestLocationAlways()
    func requestMotion()
    func requestPhotos() async
    func openSystemSettings()
}

@MainActor
final class SystemPermissionAccess: NSObject, PermissionSystemAccessing {
    nonisolated let authorizationChanges: AsyncStream<Void>

    private let locationManager: CLLocationManager
    private let motionManager: CMMotionActivityManager
    private let continuation: AsyncStream<Void>.Continuation

    override init() {
        let stream = AsyncStream.makeStream(of: Void.self)
        authorizationChanges = stream.stream
        continuation = stream.continuation
        locationManager = CLLocationManager()
        motionManager = CMMotionActivityManager()
        super.init()
        locationManager.delegate = self
    }

    var locationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    var motionStatus: CMAuthorizationStatus {
        CMMotionActivityManager.authorizationStatus()
    }

    var photoStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestLocationWhenInUse() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocationAlways() {
        locationManager.requestAlwaysAuthorization()
    }

    func requestMotion() {
        let now = Date()
        motionManager.queryActivityStarting(
            from: now.addingTimeInterval(-1), to: now, to: .main
        ) { [weak self] _, _ in
            self?.continuation.yield(())
        }
    }

    func requestPhotos() async {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        continuation.yield(())
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url)
        else { return }
        UIApplication.shared.open(url)
    }
}

extension SystemPermissionAccess: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        continuation.yield(())
    }
}
