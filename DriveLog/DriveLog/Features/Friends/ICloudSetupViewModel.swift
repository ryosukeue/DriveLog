import CloudKit
import Foundation
import Observation

@MainActor
@Observable
final class ICloudSetupViewModel {
    private(set) var status: ICloudSetupStatus = .idle
    private(set) var isConnecting = false
    private(set) var errorMessage: String?
    private(set) var successMessage: String?
    var displayName: String

    var isConnected: Bool {
        defaults.bool(forKey: "hasConnectedCloudFriends") ||
            defaults.string(forKey: "iCloudDisplayName") != nil
    }

    var canConnect: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
            let wasConnected = isConnected
            try await service.bootstrap(displayName: displayName)
            let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            defaults.set(trimmed, forKey: "iCloudDisplayName")
            defaults.set(true, forKey: "hasConnectedCloudFriends")
            successMessage = wasConnected ? "iCloudに接続済みです。表示名を更新しました。" : "iCloudに接続できました！"
            return true
        } catch {
            errorMessage = connectionErrorMessage(for: error)
            status = await service.setupStatus()
            return false
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    func dismissSuccess() {
        successMessage = nil
    }

    func disconnect() {
        defaults.removeObject(forKey: "iCloudDisplayName")
        defaults.set(false, forKey: "hasConnectedCloudFriends")
        displayName = ""
        successMessage = nil
    }

    private func connectionErrorMessage(for error: Error) -> String {
        if case CloudFriendsService.ServiceError.iCloudUnavailable = error {
            return "iCloudアカウントを確認できません。設定アプリでiCloudにサインインしてから、もう一度お試しください。"
        }
        guard let cloudError = error as? CKError else {
            return "iCloud連携中に予期しないエラーが起きました。\n\(error.localizedDescription)"
        }
        switch cloudError.code {
        case .notAuthenticated:
            return "iCloudにサインインしていません。設定アプリでiCloudにサインインしてください。"
        case .badContainer, .missingEntitlement:
            return "CloudKitコンテナの設定に問題があります。XcodeのSigning & CapabilitiesでiCloud.com.ryosukeue.DriveLogを確認してください。"
        case .permissionFailure, .serverRejectedRequest:
            return "CloudKitのアクセス権限またはスキーマ設定に問題があります。CloudKit ConsoleのDevelopment環境を確認してください。"
        case .networkUnavailable, .networkFailure:
            return "ネットワークに接続できません。通信状態を確認して、もう一度お試しください。"
        case .serviceUnavailable, .requestRateLimited, .zoneBusy:
            return "iCloudが一時的に利用できません。少し時間をおいてから、もう一度お試しください。"
        default:
            return "iCloud連携に失敗しました（CloudKit: \(cloudError.code.rawValue)）。"
        }
    }
}
