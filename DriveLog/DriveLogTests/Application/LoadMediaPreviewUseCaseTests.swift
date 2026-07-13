import AVFoundation
@testable import DriveLog
import Foundation
import Testing
import UIKit

@Suite("Load media preview use case")
@MainActor
struct LoadMediaPreviewUseCaseTests {
    @Test("loads a photo from the provider")
    func photo() async throws {
        let image = UIImage()
        let useCase = DefaultLoadMediaPreviewUseCase(
            photoLibrary: FakePhotoLibraryProvider(image: image)
        )

        #expect(try await useCase.loadPhoto(localIdentifier: "photo") === image)
    }

    @Test("rejects an empty identifier")
    func invalidIdentifier() async {
        let useCase = DefaultLoadMediaPreviewUseCase(
            photoLibrary: FakePhotoLibraryProvider()
        )

        await #expect(throws: DriveLogError.invalidData) {
            try await useCase.loadPhoto(localIdentifier: "")
        }
        await #expect(throws: DriveLogError.invalidData) {
            try await useCase.loadVideo(localIdentifier: "")
        }
    }

    @Test("loads a video from the provider")
    func video() async throws {
        let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/video.mov"))
        let useCase = DefaultLoadMediaPreviewUseCase(
            photoLibrary: FakePhotoLibraryProvider(videoAsset: asset)
        )

        #expect(try await useCase.loadVideo(localIdentifier: "video") === asset)
    }

    @Test("preserves provider failure")
    func failure() async {
        let useCase = DefaultLoadMediaPreviewUseCase(
            photoLibrary: FakePhotoLibraryProvider(error: .mediaUnavailable)
        )

        await #expect(throws: DriveLogError.mediaUnavailable) {
            try await useCase.loadPhoto(localIdentifier: "missing")
        }
    }
}
