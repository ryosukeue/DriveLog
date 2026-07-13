import AVFoundation
import Foundation
import UIKit

protocol PhotoLibraryProviding: Sendable {
    func authorizationState() async -> PhotoPermissionState
    func fetchAssets(in interval: DateInterval) async throws -> [MediaAssetReference]
    func requestThumbnail(localIdentifier: String, targetSize: CGSize) async throws -> UIImage
    func requestPhotoPreview(localIdentifier: String) async throws -> UIImage
    func requestVideoAsset(localIdentifier: String) async throws -> AVAsset
    func requestShareableResource(localIdentifier: String) async throws -> ShareableMediaResource
    var libraryChanges: AsyncStream<PhotoLibraryChange> { get }
}

enum PhotoLibraryChange: Sendable, Equatable {
    case libraryDidChange
}

struct ShareableMediaResource: Sendable, Equatable {
    let fileURL: URL
    let mediaType: MediaType
}
