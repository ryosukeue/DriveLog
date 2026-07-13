import AVFoundation
@testable import DriveLog
import Foundation
import Photos
import Testing
import UIKit

@Suite("Photo library provider")
struct PhotoLibraryProviderTests {
    @Test("maps every Photos authorization status")
    func authorizationMapping() {
        #expect(PhotoLibraryProvider.permissionState(.notDetermined) == .notDetermined)
        #expect(PhotoLibraryProvider.permissionState(.restricted) == .restricted)
        #expect(PhotoLibraryProvider.permissionState(.denied) == .denied)
        #expect(PhotoLibraryProvider.permissionState(.limited) == .limited)
        #expect(PhotoLibraryProvider.permissionState(.authorized) == .authorized)
    }

    @Test("shareable resource and change event are value types")
    func supportingValues() {
        let first = ShareableMediaResource(
            fileURL: URL(fileURLWithPath: "/tmp/photo.jpg"),
            mediaType: .photo
        )
        let second = ShareableMediaResource(
            fileURL: URL(fileURLWithPath: "/tmp/video.mov"),
            mediaType: .video
        )
        #expect(first == first)
        #expect(first != second)
        #expect(PhotoLibraryChange.libraryDidChange == .libraryDidChange)
    }

    @Test("fake returns configured assets and resources")
    @MainActor
    func fakeSuccess() async throws {
        let reference = mediaReference()
        let image = UIImage()
        let video = AVURLAsset(url: URL(fileURLWithPath: "/tmp/video.mov"))
        let resource = ShareableMediaResource(
            fileURL: URL(fileURLWithPath: "/tmp/photo.jpg"),
            mediaType: .photo
        )
        let fake = FakePhotoLibraryProvider(
            authorization: .limited,
            assets: [reference],
            image: image,
            videoAsset: video,
            shareableResource: resource
        )

        #expect(await fake.authorizationState() == .limited)
        #expect(try await fake.fetchAssets(in: interval()) == [reference])
        #expect(try await fake.requestThumbnail(localIdentifier: "asset", targetSize: .init(
            width: 80,
            height: 80
        )) === image)
        #expect(try await fake.requestPhotoPreview(localIdentifier: "asset") === image)
        #expect(try await fake.requestVideoAsset(localIdentifier: "asset") === video)
        #expect(try await fake.requestShareableResource(localIdentifier: "asset") == resource)
    }

    @Test("fake reproduces failures")
    func fakeFailure() async {
        let fake = FakePhotoLibraryProvider(error: .mediaUnavailable)
        await #expect(throws: DriveLogError.mediaUnavailable) {
            try await fake.fetchAssets(in: interval())
        }
        await #expect(throws: DriveLogError.mediaUnavailable) {
            try await fake.requestVideoAsset(localIdentifier: "missing")
        }
    }

    @Test("fake emits library changes in order")
    func fakeChanges() async {
        let fake = FakePhotoLibraryProvider()
        let task = Task { () -> [PhotoLibraryChange] in
            var iterator = fake.libraryChanges.makeAsyncIterator()
            var values: [PhotoLibraryChange] = []
            if let first = await iterator.next() {
                values.append(first)
            }
            if let second = await iterator.next() {
                values.append(second)
            }
            return values
        }
        fake.sendLibraryChange()
        fake.sendLibraryChange()
        #expect(await task.value == [.libraryDidChange, .libraryDidChange])
    }

    private func mediaReference() -> MediaAssetReference {
        MediaAssetReference(
            localIdentifier: "asset",
            mediaType: .photo,
            creationDate: interval().start,
            location: nil,
            durationSeconds: nil,
            isScreenshot: false,
            isScreenRecording: false
        )
    }

    private func interval() -> DateInterval {
        DateInterval(
            start: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 3600
        )
    }
}
