import AVFoundation
import UIKit

@MainActor
protocol LoadMediaPreviewUseCase: AnyObject {
    func loadPhoto(localIdentifier: String) async throws -> UIImage
    func loadVideo(localIdentifier: String) async throws -> AVAsset
}

@MainActor
final class DefaultLoadMediaPreviewUseCase: LoadMediaPreviewUseCase {
    private let photoLibrary: any PhotoLibraryProviding

    init(photoLibrary: any PhotoLibraryProviding) {
        self.photoLibrary = photoLibrary
    }

    func loadPhoto(localIdentifier: String) async throws -> UIImage {
        guard localIdentifier.isEmpty == false else { throw DriveLogError.invalidData }
        return try await photoLibrary.requestPhotoPreview(localIdentifier: localIdentifier)
    }

    func loadVideo(localIdentifier: String) async throws -> AVAsset {
        guard localIdentifier.isEmpty == false else { throw DriveLogError.invalidData }
        return try await photoLibrary.requestVideoAsset(localIdentifier: localIdentifier)
    }
}
