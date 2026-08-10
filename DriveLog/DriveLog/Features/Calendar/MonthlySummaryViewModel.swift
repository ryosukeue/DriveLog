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
    private var cachedSummaries: [LocalMonth: MonthlySummaryData] = [:]
    private let loadMonthlySummary: any LoadMonthlySummaryUseCase

    init(loadMonthlySummary: any LoadMonthlySummaryUseCase) {
        self.loadMonthlySummary = loadMonthlySummary
    }

    func load(month: LocalMonth) async {
        if let cached = cachedSummaries[month] {
            summary = cached
            state = state(for: cached)
            return
        }
        requestID += 1
        let currentRequestID = requestID
        state = .loading
        summary = nil
        do {
            let result = try await loadMonthlySummary.execute(month: month)
            guard currentRequestID == requestID else { return }
            cachedSummaries[month] = result
            summary = result
            state = state(for: result)
        } catch is CancellationError {
            guard currentRequestID == requestID else { return }
        } catch {
            guard currentRequestID == requestID else { return }
            state = .error
        }
    }

    private func state(for summary: MonthlySummaryData) -> MonthlySummaryViewState {
        summary.totalDistanceMeters > 0 || !summary.cityRankings.isEmpty ? .loaded : .empty
    }
}
