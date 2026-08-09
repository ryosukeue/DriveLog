import CoreLocation
import Foundation
import MapKit
import UserNotifications

nonisolated protocol NearbyGasStationProviding: Sendable {
    func isNearGasStation(latitude: Double, longitude: Double) async -> Bool
}

@MainActor
final class MapKitNearbyGasStationProvider: NearbyGasStationProviding {
    func isNearGasStation(latitude: Double, longitude: Double) async -> Bool {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard CLLocationCoordinate2DIsValid(center) else { return false }
        let request = MKLocalPointsOfInterestRequest(center: center, radius: 150)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.gasStation])
        do {
            return try await !MKLocalSearch(request: request).start().mapItems.isEmpty
        } catch {
            return false
        }
    }
}

final class FuelStopNotificationService: @unchecked Sendable {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func send(vehicleName: String, vehicleID: UUID) async {
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional
        else { return }

        let content = UNMutableNotificationContent()
        content.title = "ガソリンスタンドを検知しました"
        content.body = "給油しましたか？記録しましょう！"
        content.sound = .default
        content.userInfo = ["vehicleID": vehicleID.uuidString, "destination": "fuel"]
        let request = UNNotificationRequest(
            identifier: "fuel-stop-\(vehicleID.uuidString)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try? await notificationCenter.add(request)
    }
}
