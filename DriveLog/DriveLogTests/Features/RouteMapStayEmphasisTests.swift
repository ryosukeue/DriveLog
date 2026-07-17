@testable import DriveLog
import MapKit
import Testing

@MainActor
@Suite("Selected route stay emphasis")
struct RouteMapStayEmphasisTests {
    @Test("selected movement emphasizes only stays near its time boundaries")
    func selectedMovementStayRelationship() {
        let coordinator = RouteMapCoordinator()
        let selectedMovement = movement(start: 20 * 60 * 60 + 49 * 60, duration: 10 * 60)
        coordinator.renderedScene = MapScene(
            polylines: [], movementLabels: [selectedMovement], stayAnnotations: [],
            mediaAnnotations: [], initialRegion: nil
        )
        coordinator.selectedSegmentID = selectedMovement.segmentStableID
        let origin = stay(
            id: "origin",
            arrival: selectedMovement.startDate.timeIntervalSince1970 - 10 * 60,
            duration: 8 * 60
        )
        let destination = stay(
            id: "destination",
            arrival: selectedMovement.endDate.timeIntervalSince1970 - 6,
            duration: 30 * 60
        )
        let unrelated = stay(
            id: "unrelated",
            arrival: selectedMovement.endDate.timeIntervalSince1970 + 90 * 60,
            duration: 30 * 60
        )

        #expect(coordinator.isStayEmphasized([origin]))
        #expect(coordinator.isStayEmphasized([destination]))
        #expect(!coordinator.isStayEmphasized([unrelated]))
        #expect(coordinator.staySummary([origin, unrelated, destination]) == "前 8分・後 30分")

        coordinator.selectedSegmentID = nil
        #expect(coordinator.isStayEmphasized([unrelated]))
        #expect(coordinator.staySummary([origin, unrelated, destination]) == "滞在")
        #expect(coordinator.staySummary([origin]) == "滞在 8分")
    }

    @Test("unrelated stay marker dims while media thumbnail remains visible")
    func unrelatedStayPresentation() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        let selectedMovement = movement()
        coordinator.renderedScene = MapScene(
            polylines: [], movementLabels: [selectedMovement], stayAnnotations: [],
            mediaAnnotations: [], initialRegion: nil
        )
        coordinator.selectedSegmentID = selectedMovement.segmentStableID
        let unrelated = stay(id: "unrelated", arrival: 60 * 60, duration: 10 * 60)
        let stayAnnotation = point(
            id: unrelated.stayStableID,
            kind: .stay,
            label: "滞在 10分",
            relatedStays: [unrelated]
        )
        let mediaAnnotation = point(
            id: "media",
            kind: .media,
            mediaType: .photo,
            relatedStays: [unrelated]
        )

        let stayView = try #require(
            coordinator.mapView(mapView, viewFor: stayAnnotation) as? RouteMapStayAnnotationView
        )
        let mediaView = try #require(
            coordinator.mapView(mapView, viewFor: mediaAnnotation) as? RouteMapMediaAnnotationView
        )

        #expect(!stayView.isStayEmphasized)
        #expect(stayView.alpha == 0.22)
        #expect(!mediaView.isStayEmphasized)
        #expect(mediaView.alpha == 1)
        #expect(mediaView.displayedStayText == "滞在")
    }

    @Test("selection updates repeated stay text without exposing a count")
    func selectionUpdatesStayPresentation() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        let selectedMovement = movement(start: 1000, duration: 600)
        let preceding = stay(id: "preceding", arrival: 400, duration: 480)
        let following = stay(id: "following", arrival: 1602, duration: 1800)
        let unrelated = stay(id: "unrelated", arrival: 4000, duration: 600)
        let annotation = point(
            id: "place",
            kind: .stay,
            label: "滞在",
            relatedStays: [preceding, following, unrelated]
        )
        coordinator.renderedScene = MapScene(
            polylines: [], movementLabels: [selectedMovement], stayAnnotations: [],
            mediaAnnotations: [], initialRegion: nil
        )
        let view = try #require(
            coordinator.mapView(mapView, viewFor: annotation) as? RouteMapStayAnnotationView
        )

        coordinator.selectedSegmentID = selectedMovement.segmentStableID
        coordinator.updateStayPresentation(for: annotation, view: view)
        #expect(view.displayedText == "前 8分・後 30分")

        coordinator.selectedSegmentID = nil
        coordinator.updateStayPresentation(for: annotation, view: view)
        #expect(view.displayedText == "滞在")
        #expect(view.displayedText?.contains("回") == false)
    }

    private func movement(start: TimeInterval = 0, duration: TimeInterval = 60) -> MapMovementLabel {
        let date = Date(timeIntervalSince1970: start)
        return MapMovementLabel(
            segmentStableID: "movement",
            coordinate: RouteCoordinate(latitude: 35, longitude: 139),
            text: "1分・0.1km",
            startDate: date,
            endDate: date.addingTimeInterval(duration),
            durationSeconds: duration,
            distanceMeters: 100,
            averageSpeedMetersPerSecond: nil,
            automaticClassification: .other,
            userClassification: nil
        )
    }

    private func stay(
        id: String,
        arrival: TimeInterval,
        duration: TimeInterval
    ) -> MapStayAnnotation {
        let date = Date(timeIntervalSince1970: arrival)
        return MapStayAnnotation(
            stayStableID: id,
            coordinate: RouteCoordinate(latitude: 35, longitude: 139),
            text: "滞在",
            arrivalDate: date,
            departureDate: date.addingTimeInterval(duration),
            durationSeconds: duration,
            confidence: .medium,
            isVisibleByAutomaticRule: true
        )
    }

    private func point(
        id: String,
        kind: RouteMapPointAnnotation.Kind,
        label: String? = nil,
        mediaType: MediaType? = nil,
        relatedStays: [MapStayAnnotation]
    ) -> RouteMapPointAnnotation {
        RouteMapPointAnnotation(
            id: id,
            coordinate: CLLocationCoordinate2D(latitude: 35, longitude: 139),
            kind: kind,
            labelText: label,
            mediaType: mediaType,
            relatedStays: relatedStays
        )
    }
}
