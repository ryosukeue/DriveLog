import AVFoundation
@testable import DriveLog
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

    @Test("rejects video until the video preview issue")
    func video() async {
        let preview = MediaPreviewUseCaseFake(results: [])
        let viewModel = MediaPreviewViewModel(
            asset: asset(type: .video),
            loadPreview: preview
        )

        await viewModel.load()

        guard case .error = viewModel.state else {
            Issue.record("Expected error state")
            return
        }
        #expect(preview.photoRequests.isEmpty)
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
private final class MediaPreviewUseCaseFake: LoadMediaPreviewUseCase {
    private var results: [Result<UIImage, any Error>]
    private(set) var photoRequests: [String] = []

    init(results: [Result<UIImage, any Error>]) {
        self.results = results
    }

    func loadPhoto(localIdentifier: String) async throws -> UIImage {
        photoRequests.append(localIdentifier)
        guard results.isEmpty == false else { throw DriveLogError.mediaUnavailable }
        return try results.removeFirst().get()
    }

    func loadVideo(localIdentifier _: String) async throws -> AVAsset {
        throw DriveLogError.mediaUnavailable
    }
}
