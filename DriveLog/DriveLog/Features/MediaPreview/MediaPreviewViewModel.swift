import Observation
import UIKit

@MainActor
@Observable
final class MediaPreviewViewModel {
    enum State {
        case idle
        case loading
        case photo(UIImage)
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
        guard asset.mediaType == .photo else {
            state = .error
            return
        }
        state = .loading
        do {
            state = try await .photo(loadPreview.loadPhoto(
                localIdentifier: asset.localIdentifier
            ))
        } catch {
            state = .error
        }
    }
}
