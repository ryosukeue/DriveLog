@testable import DriveLog
import Testing
import UIKit

@Suite("Load media thumbnail use case")
@MainActor
struct LoadMediaThumbnailUseCaseTests {
    @Test("loads once and reuses the same image for an identical request")
    func cacheHit() async throws {
        let image = UIImage()
        let provider = FakePhotoLibraryProvider(image: image)
        let useCase = DefaultLoadMediaThumbnailUseCase(photoLibrary: provider)
        let size = CGSize(width: 120, height: 120)

        let first = try await useCase.execute(localIdentifier: "photo", targetSize: size)
        let second = try await useCase.execute(localIdentifier: "photo", targetSize: size)

        #expect(first === image)
        #expect(second === image)
        #expect(provider.thumbnailRequests == [
            .init(localIdentifier: "photo", targetSize: size)
        ])
    }

    @Test("uses separate cache keys for identifier and size")
    func cacheKeys() async throws {
        let provider = FakePhotoLibraryProvider()
        let useCase = DefaultLoadMediaThumbnailUseCase(photoLibrary: provider)
        let small = CGSize(width: 80, height: 80)
        let large = CGSize(width: 160, height: 160)

        _ = try await useCase.execute(localIdentifier: "first", targetSize: small)
        _ = try await useCase.execute(localIdentifier: "second", targetSize: small)
        _ = try await useCase.execute(localIdentifier: "first", targetSize: large)

        #expect(provider.thumbnailRequests == [
            .init(localIdentifier: "first", targetSize: small),
            .init(localIdentifier: "second", targetSize: small),
            .init(localIdentifier: "first", targetSize: large)
        ])
    }

    @Test("rejects invalid input without accessing the provider", arguments: [
        ThumbnailInput(localIdentifier: "", targetSize: CGSize(width: 80, height: 80)),
        ThumbnailInput(localIdentifier: "photo", targetSize: CGSize(width: 0, height: 80)),
        ThumbnailInput(localIdentifier: "photo", targetSize: CGSize(width: 80, height: -1)),
        ThumbnailInput(
            localIdentifier: "photo",
            targetSize: CGSize(width: CGFloat.infinity, height: 80)
        )
    ])
    func invalidInput(input: ThumbnailInput) async {
        let provider = FakePhotoLibraryProvider()
        let useCase = DefaultLoadMediaThumbnailUseCase(photoLibrary: provider)

        await #expect(throws: DriveLogError.invalidData) {
            try await useCase.execute(
                localIdentifier: input.localIdentifier,
                targetSize: input.targetSize
            )
        }
        #expect(provider.thumbnailRequests.isEmpty)
    }

    @Test("does not cache a provider failure")
    func failure() async {
        let provider = FakePhotoLibraryProvider(error: .mediaUnavailable)
        let useCase = DefaultLoadMediaThumbnailUseCase(photoLibrary: provider)
        let size = CGSize(width: 80, height: 80)

        for _ in 0 ..< 2 {
            await #expect(throws: DriveLogError.mediaUnavailable) {
                try await useCase.execute(localIdentifier: "missing", targetSize: size)
            }
        }
        #expect(provider.thumbnailRequests.count == 2)
    }
}

struct ThumbnailInput: Sendable, CustomTestStringConvertible {
    let localIdentifier: String
    let targetSize: CGSize

    var testDescription: String {
        "\(localIdentifier):\(targetSize.width)x\(targetSize.height)"
    }
}
