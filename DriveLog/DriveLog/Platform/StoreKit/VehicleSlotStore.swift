import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class VehicleSlotStore {
    static let productID = "com.ryosukeue.DriveLog.vehicle.slot"

    private(set) var product: Product?
    private(set) var isPurchasing = false
    private(set) var errorMessage: String?
    private(set) var purchasedSlots: Int
    private let defaults: UserDefaults

    var vehicleLimit: Int { 1 + purchasedSlots }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        purchasedSlots = defaults.integer(forKey: "purchasedVehicleSlots")
    }

    func loadProduct() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    func purchaseSlot() async -> Bool {
        guard !isPurchasing else { return false }
        guard let product else {
            errorMessage = "追加車両の購入情報を読み込めませんでした"
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case let .success(.verified(transaction)):
                purchasedSlots += 1
                defaults.set(purchasedSlots, forKey: "purchasedVehicleSlots")
                await transaction.finish()
                return true
            case .success(.unverified):
                errorMessage = "購入を確認できませんでした"
            case .pending:
                errorMessage = "購入の承認待ちです"
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "購入を完了できませんでした"
            }
        } catch {
            errorMessage = "購入を完了できませんでした。\n\(error.localizedDescription)"
        }
        return false
    }

    func dismissError() { errorMessage = nil }
}
