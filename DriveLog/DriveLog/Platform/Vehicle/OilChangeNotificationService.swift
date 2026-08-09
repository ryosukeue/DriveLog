import Foundation
import UserNotifications

final class OilChangeNotificationService: VehicleOilChangeNotifying, @unchecked Sendable {
    private let notificationCenter: UNUserNotificationCenter
    private let entitlementCache: PlusEntitlementCache

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        entitlementCache: PlusEntitlementCache = PlusEntitlementCache()
    ) {
        self.notificationCenter = notificationCenter
        self.entitlementCache = entitlementCache
    }

    func requestAuthorization() async {
        guard entitlementCache.isPlus else { return }
        _ = try? await notificationCenter.requestAuthorization(options: [.alert, .sound])
    }

    func send(_ notification: VehicleOilChangeNotification) async {
        guard entitlementCache.isPlus else { return }
        let content = UNMutableNotificationContent()
        content.sound = .default

        let identifier: String
        switch notification {
        case let .upcoming(vehicleID, vehicleName, remainingKilometers):
            identifier = "oil-change-upcoming-\(vehicleID.uuidString)"
            content.title = "そろそろオイル交換しませんか"
            content.body = "\(vehicleName)はオイル交換まであと\(remainingKilometers)kmです。"
        case let .overdue(vehicleID, vehicleName):
            identifier = "oil-change-overdue-\(vehicleID.uuidString)"
            content.title = "オイル交換時期です"
            content.body = "\(vehicleName)のオイル交換時期を迎えました。"
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        try? await notificationCenter.add(request)
    }
}
