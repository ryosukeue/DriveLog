import Foundation
import Observation

nonisolated enum MonthlyOverviewViewState: Sendable, Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error
}

@MainActor
@Observable
final class MonthlyOverviewViewModel {
    private(set) var state: MonthlyOverviewViewState = .idle
    private(set) var overview: MonthlyOverviewData?
    private var requestID = 0
    private let loadMonthlyOverview: any LoadMonthlyOverviewUseCase

    init(loadMonthlyOverview: any LoadMonthlyOverviewUseCase) {
        self.loadMonthlyOverview = loadMonthlyOverview
    }

    func load(month: LocalMonth) async {
        requestID += 1
        let currentRequestID = requestID
        state = .loading
        overview = nil
        do {
            let result = try await loadMonthlyOverview.execute(month: month)
            guard currentRequestID == requestID else { return }
            overview = result
            state = result.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            guard currentRequestID == requestID else { return }
        } catch {
            guard currentRequestID == requestID else { return }
            state = .error
        }
    }
}
