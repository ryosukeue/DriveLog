@testable import DriveLog
import Foundation
import Testing

@MainActor
@Suite("Day detail view model")
struct DayDetailViewModelTests {
    @Test("loads detail data")
    func loaded() async {
        let data = makeDayDetailData(isValid: true, isReprocessing: false)
        let viewModel = DayDetailViewModel(
            localDateKey: data.aggregate.localDateKey,
            loadDayDetail: DayDetailUseCaseFake(results: [.success(data)])
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.data?.aggregate == data.aggregate)
        #expect(!viewModel.isReprocessing)
    }

    @Test("exposes reprocessing while retaining data")
    func reprocessing() async {
        let data = makeDayDetailData(isValid: true, isReprocessing: true)
        let viewModel = DayDetailViewModel(
            localDateKey: data.aggregate.localDateKey,
            loadDayDetail: DayDetailUseCaseFake(results: [.success(data)])
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.isReprocessing)
    }

    @Test("uses empty state for invalid data and an invalid aggregate")
    func empty() async {
        let invalidDataViewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: [.failure(DriveLogError.invalidData)])
        )
        let invalidAggregate = makeDayDetailData(isValid: false, isReprocessing: false)
        let invalidAggregateViewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: [.success(invalidAggregate)])
        )

        await invalidDataViewModel.load()
        await invalidAggregateViewModel.load()

        #expect(invalidDataViewModel.state == .empty)
        #expect(invalidDataViewModel.data == nil)
        #expect(invalidAggregateViewModel.state == .empty)
    }

    @Test("shows error and succeeds when retried")
    func retry() async {
        let data = makeDayDetailData(isValid: true, isReprocessing: false)
        let fake = DayDetailUseCaseFake(results: [
            .failure(DriveLogError.persistenceFailure(code: "fixture")),
            .success(data)
        ])
        let viewModel = DayDetailViewModel(localDateKey: "2024-01-01", loadDayDetail: fake)

        await viewModel.load()
        #expect(viewModel.state == .error)
        await viewModel.load()
        #expect(viewModel.state == .loaded)
    }

    @Test("retains existing data when a reload fails")
    func retainOnError() async {
        let data = makeDayDetailData(isValid: true, isReprocessing: false)
        let fake = DayDetailUseCaseFake(results: [
            .success(data),
            .failure(DriveLogError.persistenceFailure(code: "fixture"))
        ])
        let viewModel = DayDetailViewModel(localDateKey: "2024-01-01", loadDayDetail: fake)

        await viewModel.load()
        await viewModel.load()

        #expect(viewModel.state == .error)
        #expect(viewModel.data?.aggregate == data.aggregate)
    }
}

private actor DayDetailUseCaseResultStore {
    private var results: [Result<DayDetailData, any Error>]

    init(results: [Result<DayDetailData, any Error>]) {
        self.results = results
    }

    func next() throws -> DayDetailData {
        guard !results.isEmpty else { throw DriveLogError.invalidData }
        return try results.removeFirst().get()
    }
}

private struct DayDetailUseCaseFake: LoadDayDetailUseCase {
    private let store: DayDetailUseCaseResultStore

    init(results: [Result<DayDetailData, any Error>]) {
        store = DayDetailUseCaseResultStore(results: results)
    }

    func execute(localDateKey _: String) async throws -> DayDetailData {
        try await store.next()
    }
}

private func makeDayDetailData(isValid: Bool, isReprocessing: Bool) -> DayDetailData {
    let date = Date(timeIntervalSince1970: 0)
    let aggregate = DayAggregateData(
        localDateKey: "2024-01-01", totalDistanceMeters: 1000,
        totalMovementDurationSeconds: 60, startDate: date, endDate: date.addingTimeInterval(60),
        locationRecordCount: 2, rejectedLocationCount: 0, mediaCountCache: 0,
        automaticClassification: .other, hasValidMovement: isValid,
        movementSegmentCount: 1, staySegmentCount: 0, totalStayDurationSeconds: 0,
        automotiveDurationSeconds: 0, walkingDurationSeconds: 0,
        sourceRawRevision: 1, generatedAt: date
    )
    return DayDetailData(
        aggregate: aggregate, movements: [], stays: [], media: [], mapScene: .empty,
        isReprocessing: isReprocessing
    )
}
