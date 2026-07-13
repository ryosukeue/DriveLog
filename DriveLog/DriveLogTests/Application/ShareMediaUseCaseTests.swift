@testable import DriveLog
import Foundation
import Testing

@Suite("Share media use case")
@MainActor
struct ShareMediaUseCaseTests {
    @Test("presents one resource and removes it after completion")
    func success() async throws {
        let resource = try makeResource()
        let presenter = SharePresenterSpy()
        let useCase = DefaultShareMediaUseCase(
            photoLibrary: FakePhotoLibraryProvider(shareableResource: resource),
            presenter: presenter
        )

        try await useCase.execute(localIdentifier: "photo")

        #expect(presenter.resources == [resource])
        #expect(presenter.resourceExistedDuringPresentation)
        #expect(FileManager.default.fileExists(atPath: resource.fileURL.path) == false)
    }

    @Test("removes the resource after presenter failure and preserves error")
    func presenterFailure() async throws {
        let resource = try makeResource()
        let presenter = SharePresenterSpy(error: .cancelled)
        let useCase = DefaultShareMediaUseCase(
            photoLibrary: FakePhotoLibraryProvider(shareableResource: resource),
            presenter: presenter
        )

        await #expect(throws: DriveLogError.cancelled) {
            try await useCase.execute(localIdentifier: "video")
        }
        #expect(FileManager.default.fileExists(atPath: resource.fileURL.path) == false)
    }

    @Test("rejects empty identifiers and preserves resource failure")
    func inputAndResourceFailure() async {
        let presenter = SharePresenterSpy()
        let invalid = DefaultShareMediaUseCase(
            photoLibrary: FakePhotoLibraryProvider(),
            presenter: presenter
        )
        await #expect(throws: DriveLogError.invalidData) {
            try await invalid.execute(localIdentifier: "")
        }
        #expect(presenter.resources.isEmpty)

        let unavailable = DefaultShareMediaUseCase(
            photoLibrary: FakePhotoLibraryProvider(error: .mediaUnavailable),
            presenter: presenter
        )
        await #expect(throws: DriveLogError.mediaUnavailable) {
            try await unavailable.execute(localIdentifier: "missing")
        }
        #expect(presenter.resources.isEmpty)
    }

    private func makeResource() throws -> ShareableMediaResource {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        try Data([1, 2, 3]).write(to: url)
        return ShareableMediaResource(fileURL: url, mediaType: .photo)
    }
}

@MainActor
private final class SharePresenterSpy: SharePresenting {
    private(set) var resources: [ShareableMediaResource] = []
    private(set) var resourceExistedDuringPresentation = false
    private let error: DriveLogError?

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func presentShareSheet(resource: ShareableMediaResource) async throws {
        resources.append(resource)
        resourceExistedDuringPresentation = FileManager.default.fileExists(
            atPath: resource.fileURL.path
        )
        if let error {
            throw error
        }
    }
}
