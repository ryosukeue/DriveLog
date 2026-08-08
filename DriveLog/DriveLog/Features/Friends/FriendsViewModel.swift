import Foundation
import Observation

nonisolated enum FriendsViewState: Sendable, Equatable {
    case idle
    case loading
    case loaded
    case error
}

@MainActor
@Observable
final class FriendsViewModel {
    private(set) var state: FriendsViewState = .idle
    private(set) var selectedMonth: LocalMonth
    private(set) var entries: [FriendRankingEntry] = []
    private(set) var invitationURL: URL?
    private(set) var errorMessage: String?
    private(set) var invitationMessage: String?
    let currentMonth: LocalMonth

    var canMoveToNextMonth: Bool {
        selectedMonth < currentMonth
    }

    private let service: CloudFriendsService
    private let loadMonthlyDistance: any LoadMonthlyDistanceSeriesUseCase
    private let defaults: UserDefaults

    init(
        currentMonth: LocalMonth,
        service: CloudFriendsService,
        loadMonthlyDistance: any LoadMonthlyDistanceSeriesUseCase,
        defaults: UserDefaults = .standard
    ) {
        self.currentMonth = currentMonth
        selectedMonth = currentMonth
        self.service = service
        self.loadMonthlyDistance = loadMonthlyDistance
        self.defaults = defaults
    }

    func load() async {
        await load(month: selectedMonth)
    }

    func moveToPreviousMonth() async {
        await load(month: selectedMonth.adding(months: -1))
    }

    func moveToNextMonth() async {
        guard canMoveToNextMonth else { return }
        await load(month: selectedMonth.adding(months: 1))
    }

    func prepareInvitation() async {
        do {
            invitationURL = try await service.invitationURL(displayName: displayName)
        } catch {
            errorMessage = "招待リンクを作成できませんでした"
        }
    }

    func acceptInvitation(_ url: URL) async {
        guard url.scheme?.lowercased() == "drivelog" else { return }
        do {
            try await service.acceptInvitation(url, displayName: displayName)
            invitationMessage = "友達を追加しました"
            await load()
        } catch CloudFriendsService.ServiceError.cannotAddSelf {
            errorMessage = "自分自身は友達に追加できません"
        } catch {
            errorMessage = "この招待リンクを追加できませんでした"
        }
    }

    func dismissMessages() {
        errorMessage = nil
        invitationMessage = nil
    }

    private func load(month: LocalMonth) async {
        selectedMonth = month
        state = .loading
        do {
            let series = try await loadMonthlyDistance.execute(month: month)
            entries = try await service.rankings(
                month: month,
                ownDistanceMeters: series.totalDistanceMeters,
                displayName: displayName
            )
            invitationURL = try? await service.invitationURL(displayName: displayName)
            state = .loaded
        } catch {
            entries = []
            state = .error
        }
    }

    private var displayName: String {
        defaults.string(forKey: "iCloudDisplayName") ?? "ドライバー"
    }
}
