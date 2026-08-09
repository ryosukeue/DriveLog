import Foundation
import Observation
import StoreKit

nonisolated final class PlusEntitlementCache: @unchecked Sendable {
    static let storageKey = "plus.plan.entitled.v1"

    static var grantsPlusForTesting: Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isPlus: Bool {
        Self.grantsPlusForTesting || defaults.bool(forKey: Self.storageKey)
    }

    func setIsPlus(_ value: Bool) {
        defaults.set(value, forKey: Self.storageKey)
    }
}

nonisolated enum PlusPlanPurchaseState: Sendable, Equatable {
    case idle
    case loading
    case purchasing
    case purchased
    case pending
    case unavailable
    case failed(message: String)
}

@MainActor
@Observable
final class PlusPlanStore {
    static let productID = "com.ryosukeue.DriveLog.plus.monthly"

    private(set) var product: Product?
    private(set) var isPlus: Bool
    private(set) var state: PlusPlanPurchaseState = .idle
    private(set) var hasResolvedEntitlement = false
    private(set) var isEligibleForSevenDayTrial = false

    var displayPrice: String? {
        product?.displayPrice
    }

    private let entitlementCache: PlusEntitlementCache
    private var transactionUpdatesTask: Task<Void, Never>?
    private var hasLoaded = false

    init(entitlementCache: PlusEntitlementCache = PlusEntitlementCache()) {
        self.entitlementCache = entitlementCache
        isPlus = entitlementCache.isPlus
        transactionUpdatesTask = observeTransactionUpdates()
    }

    func load() async {
        guard !hasLoaded else {
            await refreshEntitlement()
            return
        }
        state = .loading
        await refreshEntitlement()
        hasResolvedEntitlement = true
        do {
            product = try await Product.products(for: [Self.productID]).first
            isEligibleForSevenDayTrial = await eligibleForSevenDayTrial(product)
            hasLoaded = true
            state = product == nil && !isPlus ? .unavailable : .idle
        } catch {
            state = .failed(message: "Plusプランの情報を取得できませんでした")
        }
    }

    func purchase() async {
        guard let product else {
            state = .unavailable
            return
        }
        state = .purchasing
        do {
            switch try await product.purchase() {
            case let .success(result):
                let transaction = try verified(result)
                await transaction.finish()
                await refreshEntitlement()
                state = isPlus ? .purchased : .failed(message: "購入状態を確認できませんでした")
            case .pending:
                state = .pending
            case .userCancelled:
                state = .idle
            @unknown default:
                state = .failed(message: "購入を完了できませんでした")
            }
        } catch {
            state = .failed(message: "購入を完了できませんでした")
        }
    }

    func restorePurchases() async {
        state = .loading
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            state = isPlus
                ? .purchased
                : .failed(message: "復元できるPlusプランがありませんでした")
        } catch {
            state = .failed(message: "購入を復元できませんでした")
        }
    }

    func dismissMessage() {
        switch state {
        case .failed, .pending, .purchased:
            state = .idle
        case .idle, .loading, .purchasing, .unavailable:
            break
        }
    }

    private func refreshEntitlement() async {
        if PlusEntitlementCache.grantsPlusForTesting {
            isPlus = true
            return
        }
        var hasActiveEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  transaction.productID == Self.productID,
                  transaction.revocationDate == nil,
                  transaction.expirationDate.map({ $0 > Date() }) ?? true
            else { continue }
            hasActiveEntitlement = true
            break
        }
        isPlus = hasActiveEntitlement
        entitlementCache.setIsPlus(hasActiveEntitlement)
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                guard let transaction = try? Self.verifiedTransaction(result) else { continue }
                await transaction.finish()
                await self?.refreshEntitlement()
            }
        }
    }

    private func eligibleForSevenDayTrial(_ product: Product?) async -> Bool {
        guard let subscription = product?.subscription,
              let offer = subscription.introductoryOffer,
              offer.paymentMode == .freeTrial,
              await subscription.isEligibleForIntroOffer
        else { return false }
        let periodCount = max(1, offer.periodCount)
        switch offer.period.unit {
        case .day:
            return offer.period.value * periodCount == 7
        case .week:
            return offer.period.value * periodCount == 1
        case .month, .year:
            return false
        @unknown default:
            return false
        }
    }

    private func verified<Value>(_ result: VerificationResult<Value>) throws -> Value {
        switch result {
        case let .verified(value):
            return value
        case .unverified:
            throw VerificationError.unverified
        }
    }

    private nonisolated static func verifiedTransaction(
        _ result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case let .verified(transaction):
            return transaction
        case .unverified:
            throw VerificationError.unverified
        }
    }

    private enum VerificationError: Error {
        case unverified
    }
}
