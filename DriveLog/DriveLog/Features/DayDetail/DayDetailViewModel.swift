import Foundation
import Observation
import UIKit

nonisolated enum DayDetailViewState: Sendable, Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error
}

@MainActor
@Observable
final class DayDetailViewModel {
    let localDateKey: String
    private(set) var data: DayDetailData?
    private(set) var state: DayDetailViewState = .idle

    var isReprocessing: Bool {
        data?.isReprocessing == true
    }

    private let loadDayDetail: any LoadDayDetailUseCase
    private let loadMediaThumbnail: any LoadMediaThumbnailUseCase
    private let refreshMediaCache: any RefreshMediaCacheUseCase
    private let observePhotoLibraryChanges: any ObservePhotoLibraryChangesUseCase
    private var requestID: UUID?

    init(
        localDateKey: String,
        loadDayDetail: any LoadDayDetailUseCase,
        loadMediaThumbnail: any LoadMediaThumbnailUseCase,
        refreshMediaCache: any RefreshMediaCacheUseCase,
        observePhotoLibraryChanges: any ObservePhotoLibraryChangesUseCase
    ) {
        self.localDateKey = localDateKey
        self.loadDayDetail = loadDayDetail
        self.loadMediaThumbnail = loadMediaThumbnail
        self.refreshMediaCache = refreshMediaCache
        self.observePhotoLibraryChanges = observePhotoLibraryChanges
    }

    func thumbnail(localIdentifier: String, targetSize: CGSize) async throws -> UIImage {
        try await loadMediaThumbnail.execute(
            localIdentifier: localIdentifier,
            targetSize: targetSize
        )
    }

    func load() async {
        let id = UUID()
        requestID = id
        if data == nil {
            state = .loading
        }
        do {
            _ = try await refreshMediaCache.execute(localDateKey: localDateKey)
        } catch {
            // Cached day detail remains usable when PhotoKit is temporarily unavailable.
        }
        guard requestID == id, !Task.isCancelled else { return }
        do {
            let loadedData = try await loadDayDetail.execute(localDateKey: localDateKey)
            guard requestID == id else { return }
            data = loadedData
            state = loadedData.aggregate.hasValidMovement ? .loaded : .empty
        } catch DriveLogError.invalidData {
            guard requestID == id else { return }
            data = nil
            state = .empty
        } catch {
            guard requestID == id else { return }
            state = .error
        }
    }

    func observeLibraryChanges() async {
        for await _ in observePhotoLibraryChanges.changes {
            guard !Task.isCancelled else { return }
            await load()
        }
    }
}
