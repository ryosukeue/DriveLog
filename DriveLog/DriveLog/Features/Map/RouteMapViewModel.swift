import Observation

@MainActor
@Observable
final class RouteMapViewModel {
    let scene: MapScene
    let visibleMedia: [MediaAssetReference]
    private(set) var selectedSegmentID: String?
    private(set) var selectedStayID: String?

    init(scene: MapScene, media: [MediaAssetReference] = []) {
        self.scene = scene
        let references = Dictionary(
            media.filter { $0.location != nil }.map { ($0.localIdentifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        visibleMedia = scene.mediaAnnotations.compactMap {
            references[$0.localIdentifier]
        }
    }

    func selectSegment(stableID: String) {
        guard scene.movementLabels.contains(where: { $0.segmentStableID == stableID })
        else { return }
        selectedSegmentID = stableID
        selectedStayID = nil
    }

    func selectStay(stableID: String) {
        guard scene.stayAnnotations.contains(where: { $0.stayStableID == stableID })
        else { return }
        selectedStayID = stableID
        selectedSegmentID = nil
    }

    func clearSelection() {
        selectedSegmentID = nil
        selectedStayID = nil
    }

    func media(localIdentifier: String) -> MediaAssetReference? {
        visibleMedia.first { $0.localIdentifier == localIdentifier }
    }
}
