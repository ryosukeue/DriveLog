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
    private(set) var staySavingSegmentID: String?
    private(set) var stayUpdateFailed = false
    private let movementsByStableID: [String: MovementSegmentData]
    private let updateClassification: (any UpdateClassificationUseCase)?
    private let staysByStableID: [String: StayDisplayData]
    private let updateStayOverride: (any UpdateStayOverrideUseCase)?

    init(
        scene: MapScene,
        media: [MediaAssetReference] = [],
        movements: [MovementDisplayData] = [],
        updateClassification: (any UpdateClassificationUseCase)? = nil,
        stays: [StayDisplayData] = [],
        updateStayOverride: (any UpdateStayOverrideUseCase)? = nil
    ) {
        self.updateClassification = updateClassification
        self.updateStayOverride = updateStayOverride
        movementsByStableID = Dictionary(
            movements.map { ($0.segment.stableID, $0.segment) },
            uniquingKeysWith: { first, _ in first }
        )
        staysByStableID = Dictionary(
            stays.map { ($0.segment.stableID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        self.scene = scene.updatingAutomaticStayRules(staysByStableID)
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

    func updateStay(stableID: String, action: StayOverrideAction) async {
        guard staySavingSegmentID == nil,
              let display = staysByStableID[stableID],
              let updateStayOverride
        else { return }
        staySavingSegmentID = stableID
        stayUpdateFailed = false
        do {
            try await updateStayOverride.execute(stay: display.segment, action: action)
            scene = scene.applyingStayAction(action, display: display)
            let shouldClearSelection = action == .hide ||
                (action == .automatic && !display.segment.isVisibleByAutomaticRule)
            if shouldClearSelection {
                selectedStayID = nil
            }
        } catch {
            stayUpdateFailed = true
        }
        staySavingSegmentID = nil
    }

    func dismissStayError() {
        stayUpdateFailed = false
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

    func updatingAutomaticStayRules(
        _ displaysByStableID: [String: StayDisplayData]
    ) -> MapScene {
        MapScene(
            polylines: polylines,
            movementLabels: movementLabels,
            stayAnnotations: stayAnnotations.map { annotation in
                guard let display = displaysByStableID[annotation.stayStableID] else {
                    return annotation
                }
                return annotation.copy(
                    isVisibleByAutomaticRule: display.segment.isVisibleByAutomaticRule
                )
            },
            mediaAnnotations: mediaAnnotations,
            initialRegion: initialRegion
        )
    }

    func applyingStayAction(
        _ action: StayOverrideAction,
        display: StayDisplayData
    ) -> MapScene {
        let shouldDisplay = switch action {
        case .confirm:
            true
        case .hide:
            false
        case .automatic:
            display.segment.isVisibleByAutomaticRule
        }
        let stableID = display.segment.stableID
        var updated = stayAnnotations.filter { $0.stayStableID != stableID }
        if shouldDisplay, let existing = stayAnnotations.first(where: { $0.stayStableID == stableID }) {
            updated.append(existing.copy(
                isVisibleByAutomaticRule: display.segment.isVisibleByAutomaticRule
            ))
        }
        return MapScene(
            polylines: polylines,
            movementLabels: movementLabels,
            stayAnnotations: updated,
            mediaAnnotations: mediaAnnotations,
            initialRegion: initialRegion
        )
    }
}

private extension MapStayAnnotation {
    func copy(isVisibleByAutomaticRule: Bool) -> MapStayAnnotation {
        MapStayAnnotation(
            stayStableID: stayStableID,
            coordinate: coordinate,
            text: text,
            arrivalDate: arrivalDate,
            departureDate: departureDate,
            durationSeconds: durationSeconds,
            confidence: confidence,
            isVisibleByAutomaticRule: isVisibleByAutomaticRule
        )
    }
}
