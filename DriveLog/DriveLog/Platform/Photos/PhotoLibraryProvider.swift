import AVFoundation
import Photos
import UIKit

// swiftlint:disable:next line_length
final nonisolated class PhotoLibraryProvider: NSObject, PhotoLibraryProviding, PHPhotoLibraryChangeObserver, @unchecked Sendable {
    let libraryChanges: AsyncStream<PhotoLibraryChange>

    private let imageManager: PHImageManager
    private let changeContinuation: AsyncStream<PhotoLibraryChange>.Continuation

    override convenience init() {
        self.init(imageManager: PHImageManager.default())
    }

    init(imageManager: PHImageManager) {
        let stream = AsyncStream<PhotoLibraryChange>.makeStream(bufferingPolicy: .bufferingNewest(1))
        libraryChanges = stream.stream
        changeContinuation = stream.continuation
        self.imageManager = imageManager
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        changeContinuation.finish()
    }

    func authorizationState() async -> PhotoPermissionState {
        Self.permissionState(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func fetchAssets(in interval: DateInterval) async throws -> [MediaAssetReference] {
        let state = await authorizationState()
        guard state == .authorized || state == .limited else { return [] }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate < %@",
            interval.start as NSDate,
            interval.end as NSDate
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let result = PHAsset.fetchAssets(with: options)
        var references: [MediaAssetReference] = []
        references.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            guard let reference = Self.reference(asset) else { return }
            references.append(reference)
        }
        return references
    }

    func requestThumbnail(localIdentifier: String, targetSize: CGSize) async throws -> UIImage {
        let asset = try asset(localIdentifier: localIdentifier)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        return try await requestImage(asset: asset, targetSize: targetSize, options: options)
    }

    func requestPhotoPreview(localIdentifier: String) async throws -> UIImage {
        let asset = try asset(localIdentifier: localIdentifier)
        guard asset.mediaType == .image else { throw DriveLogError.mediaUnavailable }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true
        return try await requestImage(
            asset: asset,
            targetSize: PHImageManagerMaximumSize,
            options: options
        )
    }

    func requestVideoAsset(localIdentifier: String) async throws -> AVAsset {
        let asset = try asset(localIdentifier: localIdentifier)
        guard asset.mediaType == .video else { throw DriveLogError.mediaUnavailable }
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return try await withCheckedThrowingContinuation { continuation in
            imageManager.requestAVAsset(forVideo: asset, options: options) { videoAsset, _, info in
                if Self.isCancelled(info) {
                    continuation.resume(throwing: DriveLogError.cancelled)
                } else if videoAsset == nil || Self.hasError(info) {
                    continuation.resume(throwing: DriveLogError.mediaUnavailable)
                } else if let videoAsset {
                    continuation.resume(returning: videoAsset)
                }
            }
        }
    }

    func requestShareableResource(localIdentifier: String) async throws -> ShareableMediaResource {
        let asset = try asset(localIdentifier: localIdentifier)
        guard let mediaType = Self.mediaType(asset.mediaType),
              let resource = PHAssetResource.assetResources(for: asset).first
        else { throw DriveLogError.mediaUnavailable }

        let fileExtension = URL(fileURLWithPath: resource.originalFilename).pathExtension
        let fileName = fileExtension.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(fileExtension)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        do {
            try await withCheckedThrowingContinuation { continuation in
                PHAssetResourceManager.default().writeData(
                    for: resource,
                    toFile: fileURL,
                    options: options
                ) { error in
                    if error == nil {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: DriveLogError.mediaUnavailable)
                    }
                }
            }
            return ShareableMediaResource(fileURL: fileURL, mediaType: mediaType)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            throw error
        }
    }

    func photoLibraryDidChange(_: PHChange) {
        changeContinuation.yield(.libraryDidChange)
    }

    static func permissionState(_ status: PHAuthorizationStatus) -> PhotoPermissionState {
        switch status {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .limited: .limited
        case .authorized: .authorized
        @unknown default: .denied
        }
    }

    private func asset(localIdentifier: String) throws -> PHAsset {
        guard let asset = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        ).firstObject else { throw DriveLogError.mediaUnavailable }
        return asset
    }

    private func requestImage(
        asset: PHAsset,
        targetSize: CGSize,
        options: PHImageRequestOptions
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                guard Self.isDegraded(info) == false else { return }
                if Self.isCancelled(info) {
                    continuation.resume(throwing: DriveLogError.cancelled)
                } else if image == nil || Self.hasError(info) {
                    continuation.resume(throwing: DriveLogError.mediaUnavailable)
                } else if let image {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    private static func reference(_ asset: PHAsset) -> MediaAssetReference? {
        guard let mediaType = mediaType(asset.mediaType) else { return nil }
        let coordinate = asset.location.map {
            RouteCoordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        }
        return MediaAssetReference(
            localIdentifier: asset.localIdentifier,
            mediaType: mediaType,
            creationDate: asset.creationDate,
            location: coordinate,
            durationSeconds: asset.mediaType == .video ? asset.duration : nil,
            isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
            isScreenRecording: asset.mediaSubtypes.contains(.videoScreenRecording)
        )
    }

    private static func mediaType(_ type: PHAssetMediaType) -> MediaType? {
        switch type {
        case .image: .photo
        case .video: .video
        default: nil
        }
    }

    private static func isDegraded(_ info: [AnyHashable: Any]?) -> Bool {
        info?[PHImageResultIsDegradedKey] as? Bool == true
    }

    private static func isCancelled(_ info: [AnyHashable: Any]?) -> Bool {
        info?[PHImageCancelledKey] as? Bool == true
    }

    private static func hasError(_ info: [AnyHashable: Any]?) -> Bool {
        info?[PHImageErrorKey] != nil
    }
}
