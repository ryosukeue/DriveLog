import AVFoundation
import Observation
import UIKit

@MainActor
@Observable
final class MediaPreviewViewModel {
    enum State {
        case idle
        case loading
        case photo(UIImage)
        case video(AVPlayer)
        case error
    }

    let asset: MediaAssetReference
    private(set) var state: State = .idle
    private(set) var isSharing = false
    private(set) var shareFailed = false
    private let loadPreview: any LoadMediaPreviewUseCase
    private let shareMedia: (any ShareMediaUseCase)?

    init(
        asset: MediaAssetReference,
        loadPreview: any LoadMediaPreviewUseCase,
        shareMedia: (any ShareMediaUseCase)? = nil
    ) {
        self.asset = asset
        self.loadPreview = loadPreview
        self.shareMedia = shareMedia
    }

    var canShare: Bool {
        guard shareMedia != nil, isSharing == false else { return false }
        switch state {
        case .photo, .video:
            return true
        default:
            return false
        }
    }

    func load() async {
        state = .loading
        do {
            switch asset.mediaType {
            case .photo:
                state = try await .photo(loadPreview.loadPhoto(
                    localIdentifier: asset.localIdentifier
                ))
            case .video:
                let videoAsset = try await loadPreview.loadVideo(
                    localIdentifier: asset.localIdentifier
                )
                state = .video(AVPlayer(playerItem: AVPlayerItem(asset: videoAsset)))
            }
        } catch {
            state = .error
        }
    }

    func stop() {
        guard case let .video(player) = state else { return }
        player.pause()
    }

    func share() async {
        guard canShare, let shareMedia else { return }
        isSharing = true
        shareFailed = false
        defer { isSharing = false }
        do {
            try await shareMedia.execute(localIdentifier: asset.localIdentifier)
        } catch {
            shareFailed = true
        }
    }

    func clearShareError() {
        shareFailed = false
    }
}
