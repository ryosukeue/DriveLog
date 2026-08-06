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
    private var currentMonth: LocalMonth?
    private let loadMonthlyOverview: any LoadMonthlyOverviewUseCase
    private let observePhotoLibraryChanges: (any ObservePhotoLibraryChangesUseCase)?

    init(
        loadMonthlyOverview: any LoadMonthlyOverviewUseCase,
        observePhotoLibraryChanges: (any ObservePhotoLibraryChangesUseCase)? = nil
    ) {
        self.loadMonthlyOverview = loadMonthlyOverview
        self.observePhotoLibraryChanges = observePhotoLibraryChanges
    }

    func load(month: LocalMonth) async {
        currentMonth = month
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

    func observeLibraryChanges() async {
        guard let observePhotoLibraryChanges else { return }
        for await _ in observePhotoLibraryChanges.changes {
            guard !Task.isCancelled else { return }
            guard let currentMonth else { continue }
            await load(month: currentMonth)
        }
    }
}
