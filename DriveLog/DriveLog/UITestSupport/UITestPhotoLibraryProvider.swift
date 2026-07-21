#if DEBUG
    import AVFoundation
    import UIKit

    final class UITestPhotoLibraryProvider: PhotoLibraryProviding, @unchecked Sendable {
        let libraryChanges = AsyncStream<PhotoLibraryChange> { $0.finish() }
        private let assets: [MediaAssetReference]
        private let thumbnailImage: UIImage

        init(now: Date, timeZone: TimeZone) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let start = calendar.startOfDay(for: now)
            assets = [
                MediaAssetReference(
                    localIdentifier: "ui-photo",
                    mediaType: .photo,
                    creationDate: start.addingTimeInterval(3600),
                    location: RouteCoordinate(latitude: 37.350, longitude: -122.000),
                    durationSeconds: nil,
                    isScreenshot: false,
                    isScreenRecording: false
                ),
                MediaAssetReference(
                    localIdentifier: "ui-video",
                    mediaType: .video,
                    creationDate: start.addingTimeInterval(7200),
                    location: RouteCoordinate(latitude: 37.350, longitude: -122.000),
                    durationSeconds: 10,
                    isScreenshot: false,
                    isScreenRecording: false
                ),
                MediaAssetReference(
                    localIdentifier: "ui-unavailable",
                    mediaType: .photo,
                    creationDate: start.addingTimeInterval(10800),
                    location: nil,
                    durationSeconds: nil,
                    isScreenshot: false,
                    isScreenRecording: false
                )
            ]
            thumbnailImage = UIImage(systemName: "car.fill") ?? UIImage()
        }

        func authorizationState() async -> PhotoPermissionState {
            .authorized
        }

        func fetchAssets(in interval: DateInterval) async throws -> [MediaAssetReference] {
            assets.filter { asset in
                guard let creationDate = asset.creationDate else { return false }
                return interval.contains(creationDate)
            }
        }

        func requestThumbnail(localIdentifier: String, targetSize _: CGSize) async throws -> UIImage {
            guard localIdentifier != "ui-unavailable" else {
                throw DriveLogError.mediaUnavailable
            }
            return thumbnailImage
        }

        func requestPhotoPreview(localIdentifier: String) async throws -> UIImage {
            guard localIdentifier == "ui-photo" else { throw DriveLogError.mediaUnavailable }
            return thumbnailImage
        }

        func requestVideoAsset(localIdentifier: String) async throws -> AVAsset {
            guard localIdentifier == "ui-video" else { throw DriveLogError.mediaUnavailable }
            return AVURLAsset(url: URL(fileURLWithPath: "/tmp/drivelog-ui-video.mov"))
        }

        func requestShareableResource(localIdentifier: String) async throws -> ShareableMediaResource {
            guard let asset = assets.first(where: { $0.localIdentifier == localIdentifier }) else {
                throw DriveLogError.mediaUnavailable
            }
            return ShareableMediaResource(
                fileURL: URL(fileURLWithPath: "/tmp/drivelog-ui-share"),
                mediaType: asset.mediaType
            )
        }
    }
#endif
