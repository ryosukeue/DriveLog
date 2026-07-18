import Foundation
import Observation

nonisolated enum MonthlySummaryViewState: Sendable, Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error
}

@MainActor
@Observable
final class MonthlySummaryViewModel {
    private(set) var state: MonthlySummaryViewState = .idle
    private(set) var summary: MonthlySummaryData?
    private var requestID = 0
    private let loadMonthlySummary: any LoadMonthlySummaryUseCase

    init(loadMonthlySummary: any LoadMonthlySummaryUseCase) {
        self.loadMonthlySummary = loadMonthlySummary
    }

    func load(month: LocalMonth) async {
        requestID += 1
        let currentRequestID = requestID
        state = .loading
        summary = nil
        do {
            let result = try await loadMonthlySummary.execute(month: month)
            guard currentRequestID == requestID else { return }
            summary = result
            state = result.totalDistanceMeters > 0 || !result.cityRankings.isEmpty
                ? .loaded : .empty
        } catch is CancellationError {
            guard currentRequestID == requestID else { return }
        } catch {
            guard currentRequestID == requestID else { return }
            state = .error
        }
    }
}
