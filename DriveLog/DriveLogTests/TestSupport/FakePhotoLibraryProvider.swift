import AVFoundation
@testable import DriveLog
import Foundation
import UIKit

final class FakePhotoLibraryProvider: PhotoLibraryProviding, @unchecked Sendable {
    let libraryChanges: AsyncStream<PhotoLibraryChange>

    private let authorization: PhotoPermissionState
    private let assets: [MediaAssetReference]
    private let image: UIImage
    private let videoAsset: AVAsset
    private let shareableResource: ShareableMediaResource
    private let error: DriveLogError?
    private let changeContinuation: AsyncStream<PhotoLibraryChange>.Continuation

    init(
        authorization: PhotoPermissionState = .authorized,
        assets: [MediaAssetReference] = [],
        image: UIImage = UIImage(),
        videoAsset: AVAsset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/fake-video.mov")),
        shareableResource: ShareableMediaResource = ShareableMediaResource(
            fileURL: URL(fileURLWithPath: "/tmp/fake-media.jpg"),
            mediaType: .photo
        ),
        error: DriveLogError? = nil
    ) {
        let stream = AsyncStream<PhotoLibraryChange>.makeStream(bufferingPolicy: .unbounded)
        libraryChanges = stream.stream
        changeContinuation = stream.continuation
        self.authorization = authorization
        self.assets = assets
        self.image = image
        self.videoAsset = videoAsset
        self.shareableResource = shareableResource
        self.error = error
    }

    deinit {
        changeContinuation.finish()
    }

    func authorizationState() async -> PhotoPermissionState {
        authorization
    }

    func fetchAssets(in _: DateInterval) async throws -> [MediaAssetReference] {
        try throwConfiguredError()
        return assets
    }

    func requestThumbnail(localIdentifier _: String, targetSize _: CGSize) async throws -> UIImage {
        try throwConfiguredError()
        return image
    }

    func requestPhotoPreview(localIdentifier _: String) async throws -> UIImage {
        try throwConfiguredError()
        return image
    }

    func requestVideoAsset(localIdentifier _: String) async throws -> AVAsset {
        try throwConfiguredError()
        return videoAsset
    }

    func requestShareableResource(localIdentifier _: String) async throws -> ShareableMediaResource {
        try throwConfiguredError()
        return shareableResource
    }

    func sendLibraryChange() {
        changeContinuation.yield(.libraryDidChange)
    }

    private func throwConfiguredError() throws {
        if let error {
            throw error
        }
    }
}
