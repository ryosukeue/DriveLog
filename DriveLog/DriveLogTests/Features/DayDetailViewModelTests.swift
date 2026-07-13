@testable import DriveLog
import Foundation
import Testing
import UIKit

@MainActor
@Suite("Day detail view model")
struct DayDetailViewModelTests {
    @Test("loads detail data")
    func loaded() async {
        let data = makeDayDetailData(isValid: true, isReprocessing: false)
        let viewModel = DayDetailViewModel(
            localDateKey: data.aggregate.localDateKey,
            loadDayDetail: DayDetailUseCaseFake(results: [.success(data)]),
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake()
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
            loadDayDetail: DayDetailUseCaseFake(results: [.success(data)]),
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake()
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.isReprocessing)
    }

    @Test("uses empty state for invalid data and an invalid aggregate")
    func empty() async {
        let invalidDataViewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: [.failure(DriveLogError.invalidData)]),
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake()
        )
        let invalidAggregate = makeDayDetailData(isValid: false, isReprocessing: false)
        let invalidAggregateViewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: [.success(invalidAggregate)]),
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake()
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
        let viewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: fake,
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake()
        )

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
        let viewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: fake,
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake()
        )

        await viewModel.load()
        await viewModel.load()

        #expect(viewModel.state == .error)
        #expect(viewModel.data?.aggregate == data.aggregate)
    }

    @Test("loads thumbnail through the injected use case and preserves failure")
    func thumbnail() async throws {
        let image = UIImage()
        let success = DayDetailThumbnailUseCaseFake(image: image)
        let viewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: []),
            loadMediaThumbnail: success
        )
        let size = CGSize(width: 180, height: 180)

        #expect(try await viewModel.thumbnail(localIdentifier: "photo", targetSize: size) === image)
        #expect(success.requests == [.init(localIdentifier: "photo", targetSize: size)])

        let failure = DayDetailThumbnailUseCaseFake(error: .mediaUnavailable)
        let failingViewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: []),
            loadMediaThumbnail: failure
        )
        await #expect(throws: DriveLogError.mediaUnavailable) {
            try await failingViewModel.thumbnail(localIdentifier: "missing", targetSize: size)
        }
    }
}

@MainActor
private final class DayDetailThumbnailUseCaseFake: LoadMediaThumbnailUseCase {
    struct Request: Equatable {
        let localIdentifier: String
        let targetSize: CGSize
    }

    private(set) var requests: [Request] = []
    private let image: UIImage
    private let error: DriveLogError?

    init(image: UIImage = UIImage(), error: DriveLogError? = nil) {
        self.image = image
        self.error = error
    }

    func execute(localIdentifier: String, targetSize: CGSize) async throws -> UIImage {
        requests.append(Request(localIdentifier: localIdentifier, targetSize: targetSize))
        if let error {
            throw error
        }
        return image
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
