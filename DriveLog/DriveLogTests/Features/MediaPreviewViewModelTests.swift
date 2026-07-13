import AVFoundation
@testable import DriveLog
import Foundation
import Testing
import UIKit

@Suite("Media preview view model")
@MainActor
struct MediaPreviewViewModelTests {
    @Test("loads a photo and keeps sharing disabled")
    func photo() async {
        let image = UIImage()
        let preview = MediaPreviewUseCaseFake(results: [.success(image)])
        let viewModel = MediaPreviewViewModel(asset: asset(), loadPreview: preview)

        await viewModel.load()

        guard case let .photo(actual) = viewModel.state else {
            Issue.record("Expected photo state")
            return
        }
        #expect(actual === image)
        #expect(preview.photoRequests == ["photo"])
        #expect(viewModel.canShare == false)
    }

    @Test("shows error and retries")
    func retry() async {
        let image = UIImage()
        let preview = MediaPreviewUseCaseFake(results: [
            .failure(DriveLogError.mediaUnavailable),
            .success(image)
        ])
        let viewModel = MediaPreviewViewModel(asset: asset(), loadPreview: preview)

        await viewModel.load()
        guard case .error = viewModel.state else {
            Issue.record("Expected error state")
            return
        }
        await viewModel.load()
        guard case let .photo(actual) = viewModel.state else {
            Issue.record("Expected photo state after retry")
            return
        }
        #expect(actual === image)
        #expect(preview.photoRequests.count == 2)
    }

    @Test("loads video without autoplay and stops playback")
    func video() async {
        let videoAsset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/video.mov"))
        let preview = MediaPreviewUseCaseFake(results: [], videoAsset: videoAsset)
        let viewModel = MediaPreviewViewModel(
            asset: asset(type: .video),
            loadPreview: preview
        )

        await viewModel.load()

        guard case let .video(player) = viewModel.state else {
            Issue.record("Expected video state")
            return
        }
        #expect(preview.photoRequests.isEmpty)
        #expect(preview.videoRequests == ["photo"])
        #expect(player.timeControlStatus == .paused)
        player.play()
        viewModel.stop()
        #expect(player.timeControlStatus == .paused)
    }

    @Test("enables sharing after load and records share failure")
    func sharing() async {
        let image = UIImage()
        let success = ShareMediaUseCaseFake()
        let successViewModel = MediaPreviewViewModel(
            asset: asset(),
            loadPreview: MediaPreviewUseCaseFake(results: [.success(image)]),
            shareMedia: success
        )
        #expect(successViewModel.canShare == false)
        await successViewModel.load()
        #expect(successViewModel.canShare)
        await successViewModel.share()
        #expect(success.identifiers == ["photo"])
        #expect(successViewModel.isSharing == false)
        #expect(successViewModel.shareFailed == false)

        let failure = ShareMediaUseCaseFake(error: .mediaUnavailable)
        let failureViewModel = MediaPreviewViewModel(
            asset: asset(),
            loadPreview: MediaPreviewUseCaseFake(results: [.success(image)]),
            shareMedia: failure
        )
        await failureViewModel.load()
        await failureViewModel.share()
        #expect(failureViewModel.shareFailed)
        failureViewModel.clearShareError()
        #expect(failureViewModel.shareFailed == false)
    }

    private func asset(type: MediaType = .photo) -> MediaAssetReference {
        MediaAssetReference(
            localIdentifier: "photo",
            mediaType: type,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            location: RouteCoordinate(latitude: 35, longitude: 139),
            durationSeconds: type == .video ? 30 : nil,
            isScreenshot: false,
            isScreenRecording: false
        )
    }
}

@MainActor
private final class ShareMediaUseCaseFake: ShareMediaUseCase {
    private(set) var identifiers: [String] = []
    private let error: DriveLogError?

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func execute(localIdentifier: String) async throws {
        identifiers.append(localIdentifier)
        if let error {
            throw error
        }
    }
}

@MainActor
private final class MediaPreviewUseCaseFake: LoadMediaPreviewUseCase {
    private var results: [Result<UIImage, any Error>]
    private(set) var photoRequests: [String] = []
    private(set) var videoRequests: [String] = []
    private let videoAsset: AVAsset

    init(
        results: [Result<UIImage, any Error>],
        videoAsset: AVAsset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/video.mov"))
    ) {
        self.results = results
        self.videoAsset = videoAsset
    }

    func loadPhoto(localIdentifier: String) async throws -> UIImage {
        photoRequests.append(localIdentifier)
        guard results.isEmpty == false else { throw DriveLogError.mediaUnavailable }
        return try results.removeFirst().get()
    }

    func loadVideo(localIdentifier: String) async throws -> AVAsset {
        videoRequests.append(localIdentifier)
        return videoAsset
    }
}
