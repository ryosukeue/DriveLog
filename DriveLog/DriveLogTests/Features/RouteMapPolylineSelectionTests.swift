@testable import DriveLog
import MapKit
import Testing

@MainActor
@Suite("Route map polyline selection")
struct RouteMapPolylineSelectionTests {
    @Test("movement labels are not added as visible annotations")
    func movementLabelsAreHidden() {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        coordinator.addAnnotations(
            scene: MapScene(
                polylines: [], movementLabels: [movement()],
                stayAnnotations: [], mediaAnnotations: [], initialRegion: nil
            ),
            to: mapView
        )

        #expect(mapView.annotations.isEmpty)
    }

    @Test("selected polyline is thicker and more opaque than other routes")
    func selectedPolylineEmphasis() throws {
        let coordinator = RouteMapCoordinator()
        let coordinates = [
            CLLocationCoordinate2D(latitude: 35, longitude: 139),
            CLLocationCoordinate2D(latitude: 35.001, longitude: 139.001)
        ]
        let selected = MKPolyline(coordinates: coordinates, count: coordinates.count)
        selected.title = "selected"
        let other = MKPolyline(coordinates: coordinates, count: coordinates.count)
        other.title = "other"

        let selectedRenderer = try #require(
            coordinator.mapView(MKMapView(), rendererFor: selected) as? MKPolylineRenderer
        )
        #expect(selectedRenderer.lineWidth == 4)
        let initialColor = try #require(selectedRenderer.strokeColor)
        #expect(initialColor.cgColor.alpha == 1)

        coordinator.selectedSegmentID = "selected"
        coordinator.applyPolylineStyle(to: selectedRenderer, stableID: selected.title)
        let otherRenderer = try #require(
            coordinator.mapView(MKMapView(), rendererFor: other) as? MKPolylineRenderer
        )

        #expect(selectedRenderer.lineWidth == 8)
        #expect(otherRenderer.lineWidth == 3)
        let selectedColor = try #require(selectedRenderer.strokeColor)
        let otherColor = try #require(otherRenderer.strokeColor)
        #expect(selectedColor.cgColor.alpha == 1)
        #expect(otherColor.cgColor.alpha == 0.45)
    }

    @Test("polyline hit testing uses a 44 point touch target")
    func polylineHitTarget() {
        let mapView = configuredMapView()
        let coordinates = [
            CLLocationCoordinate2D(latitude: 35, longitude: 138.995),
            CLLocationCoordinate2D(latitude: 35, longitude: 139.005)
        ]
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        let coordinator = RouteMapCoordinator()
        let center = mapView.convert(
            CLLocationCoordinate2D(latitude: 35, longitude: 139),
            toPointTo: mapView
        )

        #expect(coordinator.isTap(CGPoint(x: center.x, y: center.y + 21), near: polyline, in: mapView))
        #expect(!coordinator.isTap(CGPoint(x: center.x, y: center.y + 23), near: polyline, in: mapView))
    }

    @Test("direct polyline selection immediately adds a visible detail callout")
    func directPolylineSelection() throws {
        let mapView = configuredMapView()
        let coordinates = [
            RouteCoordinate(latitude: 35, longitude: 138.995),
            RouteCoordinate(latitude: 35, longitude: 139.005)
        ]
        let coordinator = RouteMapCoordinator()
        var selectedID: String?
        coordinator.onSelectSegment = { selectedID = $0 }
        coordinator.update(
            scene: MapScene(
                polylines: [MapPolyline(segmentStableID: "movement", coordinates: coordinates)],
                movementLabels: [movement()],
                stayAnnotations: [], mediaAnnotations: [], initialRegion: nil
            ),
            in: mapView
        )
        let center = mapView.convert(
            CLLocationCoordinate2D(latitude: 35, longitude: 139),
            toPointTo: mapView
        )

        #expect(coordinator.selectPolyline(at: center, in: mapView))
        #expect(selectedID == "movement")
        let annotation = try #require(mapView.annotations.first as? RouteMapPointAnnotation)
        #expect(annotation.kind == .movementCallout)
        let view = try #require(
            coordinator.mapView(mapView, viewFor: annotation) as? RouteMapMovementCalloutView
        )
        #expect(view.displayedItems.count == 4)
        #expect(view.displayPriority == .required)
    }

    @Test("map navigation gestures take priority over the polyline tap recognizer")
    func navigationGesturePriority() {
        let coordinator = RouteMapCoordinator()
        let tap = UITapGestureRecognizer()

        #expect(!coordinator.gestureRecognizer(
            tap,
            shouldRecognizeSimultaneouslyWith: UIPinchGestureRecognizer()
        ))
        #expect(!coordinator.gestureRecognizer(
            tap,
            shouldRecognizeSimultaneouslyWith: UIPanGestureRecognizer()
        ))
        #expect(coordinator.gestureRecognizer(
            tap,
            shouldRecognizeSimultaneouslyWith: UITapGestureRecognizer()
        ))
    }

    private func configuredMapView() -> MKMapView {
        let mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        mapView.setRegion(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35, longitude: 139),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ),
            animated: false
        )
        return mapView
    }

    private func movement() -> MapMovementLabel {
        let date = Date(timeIntervalSince1970: 0)
        return MapMovementLabel(
            segmentStableID: "movement",
            coordinate: RouteCoordinate(latitude: 35, longitude: 139),
            text: "1分・0.1km",
            startDate: date,
            endDate: date.addingTimeInterval(60),
            durationSeconds: 60,
            distanceMeters: 100,
            averageSpeedMetersPerSecond: nil,
            automaticClassification: .other,
            userClassification: nil
        )
    }
}
