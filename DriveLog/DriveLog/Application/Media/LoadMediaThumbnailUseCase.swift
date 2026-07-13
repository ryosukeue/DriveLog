import UIKit

@MainActor
protocol LoadMediaThumbnailUseCase: AnyObject {
    func execute(localIdentifier: String, targetSize: CGSize) async throws -> UIImage
}

@MainActor
final class DefaultLoadMediaThumbnailUseCase: LoadMediaThumbnailUseCase {
    private let photoLibrary: any PhotoLibraryProviding
    private let cache = NSCache<ThumbnailCacheKey, UIImage>()

    init(photoLibrary: any PhotoLibraryProviding) {
        self.photoLibrary = photoLibrary
    }

    func execute(localIdentifier: String, targetSize: CGSize) async throws -> UIImage {
        guard localIdentifier.isEmpty == false,
              targetSize.width.isFinite,
              targetSize.height.isFinite,
              targetSize.width > 0,
              targetSize.height > 0
        else { throw DriveLogError.invalidData }

        let key = ThumbnailCacheKey(localIdentifier: localIdentifier, targetSize: targetSize)
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let image = try await photoLibrary.requestThumbnail(
            localIdentifier: localIdentifier,
            targetSize: targetSize
        )
        cache.setObject(image, forKey: key)
        return image
    }
}

private final class ThumbnailCacheKey: NSObject {
    private let localIdentifier: String
    private let targetSize: CGSize

    init(localIdentifier: String, targetSize: CGSize) {
        self.localIdentifier = localIdentifier
        self.targetSize = targetSize
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(localIdentifier)
        hasher.combine(targetSize.width)
        hasher.combine(targetSize.height)
        return hasher.finalize()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ThumbnailCacheKey else { return false }
        return localIdentifier == other.localIdentifier && targetSize == other.targetSize
    }
}
