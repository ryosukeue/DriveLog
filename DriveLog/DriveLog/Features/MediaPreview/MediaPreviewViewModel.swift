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
    private let loadPreview: any LoadMediaPreviewUseCase

    init(asset: MediaAssetReference, loadPreview: any LoadMediaPreviewUseCase) {
        self.asset = asset
        self.loadPreview = loadPreview
    }

    var canShare: Bool {
        false
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
}
