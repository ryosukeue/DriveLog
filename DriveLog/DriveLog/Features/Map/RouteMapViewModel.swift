import Observation

@MainActor
@Observable
final class RouteMapViewModel {
    private(set) var scene: MapScene
    let visibleMedia: [MediaAssetReference]
    private(set) var selectedSegmentID: String?
    private(set) var selectedStayID: String?
    private(set) var classificationSavingSegmentID: String?
    private(set) var classificationUpdateFailed = false
    private let movementsByStableID: [String: MovementSegmentData]
    private let updateClassification: (any UpdateClassificationUseCase)?

    init(
        scene: MapScene,
        media: [MediaAssetReference] = [],
        movements: [MovementDisplayData] = [],
        updateClassification: (any UpdateClassificationUseCase)? = nil
    ) {
        self.scene = scene
        self.updateClassification = updateClassification
        movementsByStableID = Dictionary(
            movements.map { ($0.segment.stableID, $0.segment) },
            uniquingKeysWith: { first, _ in first }
        )
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

    func updateClassification(
        stableID: String,
        classification: UserMovementClassification
    ) async {
        guard classificationSavingSegmentID == nil,
              let segment = movementsByStableID[stableID],
              let updateClassification
        else { return }
        classificationSavingSegmentID = stableID
        classificationUpdateFailed = false
        do {
            try await updateClassification.execute(
                segment: segment,
                classification: classification
            )
            scene = scene.updatingClassification(
                stableID: stableID,
                classification: classification
            )
        } catch {
            classificationUpdateFailed = true
        }
        classificationSavingSegmentID = nil
    }

    func dismissClassificationError() {
        classificationUpdateFailed = false
    }
}

private extension MapScene {
    func updatingClassification(
        stableID: String,
        classification: UserMovementClassification
    ) -> MapScene {
        MapScene(
            polylines: polylines,
            movementLabels: movementLabels.map { movement in
                guard movement.segmentStableID == stableID else { return movement }
                return MapMovementLabel(
                    segmentStableID: movement.segmentStableID,
                    coordinate: movement.coordinate,
                    text: movement.text,
                    startDate: movement.startDate,
                    endDate: movement.endDate,
                    durationSeconds: movement.durationSeconds,
                    distanceMeters: movement.distanceMeters,
                    averageSpeedMetersPerSecond: movement.averageSpeedMetersPerSecond,
                    automaticClassification: movement.automaticClassification,
                    userClassification: classification
                )
            },
            stayAnnotations: stayAnnotations,
            mediaAnnotations: mediaAnnotations,
            initialRegion: initialRegion
        )
    }
}
