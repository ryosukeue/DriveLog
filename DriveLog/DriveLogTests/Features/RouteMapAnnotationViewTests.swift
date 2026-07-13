@testable import DriveLog
import MapKit
import Testing

@MainActor
@Suite("Route map annotation views")
struct RouteMapAnnotationViewTests {
    @Test("media annotations participate in media-only clustering")
    func mediaClustering() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        let annotation = point(id: "media", kind: .media, mediaType: .video)

        let view = try #require(
            coordinator.mapView(mapView, viewFor: annotation) as? RouteMapMediaAnnotationView
        )

        #expect(view.clusteringIdentifier == "media")
        #expect(view.collisionMode == .rectangle)
        #expect(view.accessibilityLabel == "動画")
        #expect(view.accessibilityIdentifier == "map.mediaAnnotation")
    }

    @Test("cluster annotations display member count accessibly")
    func clusterCount() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        let cluster = MKClusterAnnotation(memberAnnotations: [
            point(id: "one", kind: .media, mediaType: .photo),
            point(id: "two", kind: .media, mediaType: .video)
        ])

        let view = try #require(
            coordinator.mapView(mapView, viewFor: cluster) as?
                RouteMapMediaClusterAnnotationView
        )

        #expect(view.glyphText == "2")
        #expect(view.accessibilityLabel == "2件の写真と動画")
        #expect(view.accessibilityIdentifier == "map.mediaCluster")
        #expect(view.collisionMode == .circle)
    }

    @Test("movement and stay annotations do not cluster")
    func nonMediaDoesNotCluster() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        let movement = try #require(coordinator.mapView(
            mapView,
            viewFor: point(id: "movement", kind: .movementLabel, label: "1分")
        ))
        let stay = try #require(coordinator.mapView(
            mapView,
            viewFor: point(id: "stay", kind: .stay, label: "5分")
        ))

        #expect(movement.clusteringIdentifier == nil)
        #expect(stay.clusteringIdentifier == nil)
    }
}

@MainActor
private func point(
    id: String,
    kind: RouteMapPointAnnotation.Kind,
    label: String? = nil,
    mediaType: MediaType? = nil
) -> RouteMapPointAnnotation {
    RouteMapPointAnnotation(
        id: id,
        coordinate: CLLocationCoordinate2D(latitude: 35, longitude: 139),
        kind: kind,
        labelText: label,
        mediaType: mediaType
    )
}
