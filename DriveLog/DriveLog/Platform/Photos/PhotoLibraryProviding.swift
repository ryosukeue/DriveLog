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

nonisolated enum PhotoLibraryChange: Sendable, Equatable {
    case libraryDidChange
}

nonisolated struct ShareableMediaResource: Sendable, Equatable {
    let fileURL: URL
    let mediaType: MediaType
}
