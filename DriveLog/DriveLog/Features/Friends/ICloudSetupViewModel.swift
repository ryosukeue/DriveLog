import Foundation
import Observation

@MainActor
@Observable
final class ICloudSetupViewModel {
    private(set) var status: ICloudSetupStatus = .idle
    private(set) var isConnecting = false
    private(set) var errorMessage: String?
    var displayName: String

    private let service: CloudFriendsService
    private let defaults: UserDefaults

    init(
        service: CloudFriendsService,
        defaults: UserDefaults = .standard
    ) {
        self.service = service
        self.defaults = defaults
        displayName = defaults.string(forKey: "iCloudDisplayName") ?? ""
    }

    func check() async {
        status = .checking
        status = await service.setupStatus()
    }

    func connect() async -> Bool {
        guard !isConnecting else { return false }
        isConnecting = true
        errorMessage = nil
        defer { isConnecting = false }
        do {
            try await service.bootstrap(displayName: displayName)
            let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            defaults.set(trimmed.isEmpty ? "ドライバー" : trimmed, forKey: "iCloudDisplayName")
            return true
        } catch {
            errorMessage = "iCloudに接続できませんでした。" +
                "設定と通信状態を確認してください。"
            status = await service.setupStatus()
            return false
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
