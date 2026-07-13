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
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake(),
            refreshMediaCache: DayDetailRefreshUseCaseFake(),
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
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
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake(),
            refreshMediaCache: DayDetailRefreshUseCaseFake(),
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
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
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake(),
            refreshMediaCache: DayDetailRefreshUseCaseFake(),
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
        )
        let invalidAggregate = makeDayDetailData(isValid: false, isReprocessing: false)
        let invalidAggregateViewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: [.success(invalidAggregate)]),
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake(),
            refreshMediaCache: DayDetailRefreshUseCaseFake(),
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
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
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake(),
            refreshMediaCache: DayDetailRefreshUseCaseFake(),
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
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
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake(),
            refreshMediaCache: DayDetailRefreshUseCaseFake(),
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
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
            loadMediaThumbnail: success,
            refreshMediaCache: DayDetailRefreshUseCaseFake(),
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
        )
        let size = CGSize(width: 180, height: 180)

        #expect(try await viewModel.thumbnail(localIdentifier: "photo", targetSize: size) === image)
        #expect(success.requests == [.init(localIdentifier: "photo", targetSize: size)])

        let failure = DayDetailThumbnailUseCaseFake(error: .mediaUnavailable)
        let failingViewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: []),
            loadMediaThumbnail: failure,
            refreshMediaCache: DayDetailRefreshUseCaseFake(),
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
        )
        await #expect(throws: DriveLogError.mediaUnavailable) {
            try await failingViewModel.thumbnail(localIdentifier: "missing", targetSize: size)
        }
    }

    @Test("refreshes media before loading and tolerates refresh failure")
    func refreshBeforeLoad() async {
        let data = makeDayDetailData(isValid: true, isReprocessing: false)
        let success = DayDetailRefreshUseCaseFake()
        let successViewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: [.success(data)]),
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake(),
            refreshMediaCache: success,
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
        )
        let failure = DayDetailRefreshUseCaseFake(error: .mediaUnavailable)
        let failureViewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: [.success(data)]),
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake(),
            refreshMediaCache: failure,
            observePhotoLibraryChanges: DayDetailObserveChangesFake()
        )

        await successViewModel.load()
        await failureViewModel.load()

        #expect(await success.recordedKeys() == ["2024-01-01"])
        #expect(await failure.recordedKeys() == ["2024-01-01"])
        #expect(successViewModel.state == .loaded)
        #expect(failureViewModel.state == .loaded)
    }

    @Test("library changes refresh and reload until observation is cancelled")
    func libraryChanges() async {
        let first = makeDayDetailData(isValid: true, isReprocessing: false)
        let second = makeDayDetailData(isValid: true, isReprocessing: true)
        let refresh = DayDetailRefreshUseCaseFake()
        let source = DayDetailChangeSource()
        let viewModel = DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DayDetailUseCaseFake(results: [.success(first), .success(second)]),
            loadMediaThumbnail: DayDetailThumbnailUseCaseFake(),
            refreshMediaCache: refresh,
            observePhotoLibraryChanges: DayDetailObserveChangesFake(changes: source.changes)
        )
        let observation = Task { await viewModel.observeLibraryChanges() }

        source.send()
        await waitUntil { await refresh.recordedKeys().count == 1 }
        await waitUntil { viewModel.state == .loaded }
        #expect(!viewModel.isReprocessing)

        source.send()
        await waitUntil { await refresh.recordedKeys().count == 2 }
        await waitUntil { viewModel.isReprocessing }
        #expect(viewModel.isReprocessing)

        observation.cancel()
        await observation.value
        source.send()
        for _ in 0 ..< 10 {
            await Task.yield()
        }
        #expect(await refresh.recordedKeys().count == 2)
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

private actor DayDetailRefreshUseCaseFake: RefreshMediaCacheUseCase {
    private var keys: [String] = []
    private let error: DriveLogError?

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func execute(localDateKey: String) async throws -> [MediaAssetReference] {
        keys.append(localDateKey)
        if let error {
            throw error
        }
        return []
    }

    func recordedKeys() -> [String] {
        keys
    }
}

private struct DayDetailObserveChangesFake: ObservePhotoLibraryChangesUseCase {
    let changes: AsyncStream<PhotoLibraryChange>

    init(changes: AsyncStream<PhotoLibraryChange> = AsyncStream { $0.finish() }) {
        self.changes = changes
    }
}

private final class DayDetailChangeSource: @unchecked Sendable {
    let changes: AsyncStream<PhotoLibraryChange>
    private let continuation: AsyncStream<PhotoLibraryChange>.Continuation

    init() {
        let stream = AsyncStream<PhotoLibraryChange>.makeStream(bufferingPolicy: .unbounded)
        changes = stream.stream
        continuation = stream.continuation
    }

    deinit {
        continuation.finish()
    }

    func send() {
        continuation.yield(.libraryDidChange)
    }
}

private func waitUntil(_ condition: () async -> Bool) async {
    for _ in 0 ..< 100 {
        if await condition() {
            return
        }
        await Task.yield()
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
