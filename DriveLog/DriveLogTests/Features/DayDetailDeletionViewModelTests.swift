@testable import DriveLog
import Foundation
import Testing
import UIKit

@MainActor
@Suite("Day detail deletion view model")
struct DayDetailDeletionViewModelTests {
    @Test("deletes once and performs success haptic")
    func success() async {
        let deletion = DayDetailDeleteUseCaseFake()
        let haptic = DayDetailHapticSpy()
        let viewModel = makeViewModel(deleteDayLog: deletion, hapticFeedback: haptic)

        #expect(await viewModel.deleteDay())

        #expect(await deletion.recordedKeys() == ["2024-01-01"])
        #expect(haptic.callCount == 1)
        #expect(!viewModel.isDeleting)
        #expect(!viewModel.deletionFailed)
    }

    @Test("retains detail and exposes an error when deletion fails")
    func failure() async {
        let deletion = DayDetailDeleteUseCaseFake(error: .persistenceFailure(code: "delete"))
        let haptic = DayDetailHapticSpy()
        let viewModel = makeViewModel(deleteDayLog: deletion, hapticFeedback: haptic)

        #expect(await viewModel.deleteDay() == false)

        #expect(viewModel.deletionFailed)
        #expect(haptic.callCount == 0)
        viewModel.dismissDeletionError()
        #expect(!viewModel.deletionFailed)
    }

    @Test("ignores a concurrent deletion request")
    func reentry() async {
        let gate = DayDetailDeleteGate()
        let viewModel = makeViewModel(deleteDayLog: gate)
        let first = Task { await viewModel.deleteDay() }
        await gate.waitUntilStarted()

        #expect(await viewModel.deleteDay() == false)
        await gate.resume()
        #expect(await first.value)
        #expect(await gate.recordedKeys() == ["2024-01-01"])
    }

    private func makeViewModel(
        deleteDayLog: any DeleteDayLogUseCase,
        hapticFeedback: (any HapticFeedbackProviding)? = nil
    ) -> DayDetailViewModel {
        DayDetailViewModel(
            localDateKey: "2024-01-01",
            loadDayDetail: DeletionUnusedDetailLoader(),
            loadMediaThumbnail: DeletionUnusedThumbnailLoader(),
            refreshMediaCache: DeletionUnusedMediaRefresher(),
            observePhotoLibraryChanges: DeletionFinishedObserver(),
            deleteDayLog: deleteDayLog,
            hapticFeedback: hapticFeedback
        )
    }
}

private actor DayDetailDeleteUseCaseFake: DeleteDayLogUseCase {
    private var keys: [String] = []
    private let error: DriveLogError?

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func execute(localDateKey: String) throws {
        keys.append(localDateKey)
        if let error {
            throw error
        }
    }

    func recordedKeys() -> [String] {
        keys
    }
}

private actor DayDetailDeleteGate: DeleteDayLogUseCase {
    private var keys: [String] = []
    private var continuation: CheckedContinuation<Void, Never>?

    func execute(localDateKey: String) async {
        keys.append(localDateKey)
        await withCheckedContinuation { continuation = $0 }
    }

    func waitUntilStarted() async {
        while keys.isEmpty {
            await Task.yield()
        }
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }

    func recordedKeys() -> [String] {
        keys
    }
}

@MainActor
private final class DayDetailHapticSpy: HapticFeedbackProviding {
    private(set) var callCount = 0

    func performLightSuccess() {
        callCount += 1
    }
}

private struct DeletionUnusedDetailLoader: LoadDayDetailUseCase {
    func execute(localDateKey _: String) async throws -> DayDetailData {
        throw DriveLogError.invalidData
    }
}

@MainActor
private final class DeletionUnusedThumbnailLoader: LoadMediaThumbnailUseCase {
    func execute(localIdentifier _: String, targetSize _: CGSize) async throws -> UIImage {
        throw DriveLogError.mediaUnavailable
    }
}

private struct DeletionUnusedMediaRefresher: RefreshMediaCacheUseCase {
    func execute(localDateKey _: String) async throws -> [MediaAssetReference] {
        []
    }
}

private struct DeletionFinishedObserver: ObservePhotoLibraryChangesUseCase {
    let changes = AsyncStream<PhotoLibraryChange> { $0.finish() }
}
