import Observation

@MainActor
@Observable
final class RouteMapViewModel {
    private(set) var scene: MapScene
    let visibleMedia: [MediaAssetReference]
    private(set) var selectedSegmentID: String?
    private(set) var selectedStayID: String?
    private(set) var staySavingSegmentID: String?
    private(set) var stayUpdateFailed = false
    private let staysByStableID: [String: StayDisplayData]
    private let updateStayOverride: (any UpdateStayOverrideUseCase)?
    private let hapticFeedback: (any HapticFeedbackProviding)?

    init(
        scene: MapScene,
        media: [MediaAssetReference] = [],
        movements _: [MovementDisplayData] = [],
        stays: [StayDisplayData] = [],
        updateStayOverride: (any UpdateStayOverrideUseCase)? = nil,
        hapticFeedback: (any HapticFeedbackProviding)? = nil
    ) {
        self.updateStayOverride = updateStayOverride
        self.hapticFeedback = hapticFeedback
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

    func media(
        atPlaceContaining localIdentifiers: [String],
        maximumDistanceMeters: Double = ProcessingConfiguration.mvp.stay.stayRadius
    ) -> [MediaAssetReference] {
        let identifiers = Set(localIdentifiers)
        let anchors = visibleMedia.filter {
            identifiers.contains($0.localIdentifier)
        }.compactMap(\.location)
        guard !anchors.isEmpty else {
            return visibleMedia.filter { identifiers.contains($0.localIdentifier) }
        }
        let distanceCalculator = GeodesicDistanceCalculator()
        var mediaAtPlace: [MediaAssetReference] = []
        for asset in visibleMedia {
            if identifiers.contains(asset.localIdentifier) {
                mediaAtPlace.append(asset)
                continue
            }
            guard let location = asset.location else {
                continue
            }
            for anchor in anchors where distanceCalculator.meters(
                fromLatitude: anchor.latitude,
                longitude: anchor.longitude,
                toLatitude: location.latitude,
                longitude: location.longitude
            ) <= maximumDistanceMeters {
                mediaAtPlace.append(asset)
                break
            }
        }
        return mediaAtPlace
    }

    func stays(stableIDs: [String]) -> [StayDisplayData] {
        stableIDs.compactMap { staysByStableID[$0] }.sorted {
            $0.segment.estimatedArrivalDate < $1.segment.estimatedArrivalDate
        }
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
            hapticFeedback?.performLightSuccess()
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
