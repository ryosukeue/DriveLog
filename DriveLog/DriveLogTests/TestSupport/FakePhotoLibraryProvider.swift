import AVFoundation
@testable import DriveLog
import Foundation
import os
import UIKit

final class FakePhotoLibraryProvider: PhotoLibraryProviding, @unchecked Sendable {
    struct ThumbnailRequest: Sendable, Equatable {
        let localIdentifier: String
        let targetSize: CGSize
    }

    let libraryChanges: AsyncStream<PhotoLibraryChange>

    private let authorization: PhotoPermissionState
    private let assets: [MediaAssetReference]
    private let image: UIImage
    private let videoAsset: AVAsset
    private let shareableResource: ShareableMediaResource
    private let error: DriveLogError?
    private let changeContinuation: AsyncStream<PhotoLibraryChange>.Continuation
    private let fetchStorage = OSAllocatedUnfairLock(initialState: [DateInterval]())
    private let thumbnailStorage = OSAllocatedUnfairLock(initialState: [ThumbnailRequest]())

    var fetchedIntervals: [DateInterval] {
        fetchStorage.withLock { $0 }
    }

    var thumbnailRequests: [ThumbnailRequest] {
        thumbnailStorage.withLock { $0 }
    }

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

    func fetchAssets(in interval: DateInterval) async throws -> [MediaAssetReference] {
        fetchStorage.withLock { $0.append(interval) }
        try throwConfiguredError()
        return assets
    }

    func requestThumbnail(localIdentifier: String, targetSize: CGSize) async throws -> UIImage {
        thumbnailStorage.withLock {
            $0.append(ThumbnailRequest(
                localIdentifier: localIdentifier,
                targetSize: targetSize
            ))
        }
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
