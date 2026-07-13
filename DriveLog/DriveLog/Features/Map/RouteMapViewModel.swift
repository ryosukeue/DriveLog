import Observation

@MainActor
@Observable
final class RouteMapViewModel {
    let scene: MapScene
    private(set) var selectedSegmentID: String?
    private(set) var selectedStayID: String?

    init(scene: MapScene) {
        self.scene = scene
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
}
