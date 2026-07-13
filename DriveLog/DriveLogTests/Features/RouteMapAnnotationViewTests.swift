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

    @Test("movement callout provides all classification choices")
    func classificationMenu() throws {
        let view = RouteMapMovementCalloutView(annotation: nil, reuseIdentifier: nil)
        try view.configure(
            movement: movement(userClassification: .train),
            formatter: DayDetailFormatter(timeZone: #require(TimeZone(identifier: "UTC")))
        )

        let button = try #require(view.subviews.compactMap { $0 as? UIButton }.first)
        let actions = try #require(button.menu?.children.compactMap { $0 as? UIAction })
        #expect(actions.map(\.title) == ["車", "電車", "バス", "徒歩", "その他"])
        #expect(actions.map(\.state) == [.off, .on, .off, .off, .off])
        #expect(button.isEnabled)
        #expect(button.accessibilityIdentifier == "map.classificationMenu")
    }

    @Test("movement classification menu disables while saving")
    func classificationSaving() throws {
        let view = RouteMapMovementCalloutView(annotation: nil, reuseIdentifier: nil)
        try view.configure(
            movement: movement(userClassification: nil),
            formatter: DayDetailFormatter(timeZone: #require(TimeZone(identifier: "UTC"))),
            isSaving: true
        )

        let button = try #require(view.subviews.compactMap { $0 as? UIButton }.first)
        #expect(button.isEnabled == false)
        #expect(button.title(for: .normal) == "保存中…")
    }

    @Test("stay callout provides all override actions")
    func stayOverrideMenu() throws {
        let view = RouteMapStayCalloutView(annotation: nil, reuseIdentifier: nil)
        try view.configure(
            stay: stay(),
            formatter: DayDetailFormatter(timeZone: #require(TimeZone(identifier: "UTC")))
        )

        let button = try #require(view.subviews.compactMap { $0 as? UIButton }.first)
        let actions = try #require(button.menu?.children.compactMap { $0 as? UIAction })
        #expect(actions.map(\.title) == ["立ち寄りとして確定", "非表示", "自動判定へ戻す"])
        #expect(actions[1].attributes.contains(.destructive))
        #expect(button.isEnabled)
        #expect(button.accessibilityIdentifier == "map.stayOverrideMenu")
    }

    @Test("stay override menu disables while saving")
    func stayOverrideSaving() throws {
        let view = RouteMapStayCalloutView(annotation: nil, reuseIdentifier: nil)
        try view.configure(
            stay: stay(),
            formatter: DayDetailFormatter(timeZone: #require(TimeZone(identifier: "UTC"))),
            isSaving: true
        )

        let button = try #require(view.subviews.compactMap { $0 as? UIButton }.first)
        #expect(button.isEnabled == false)
        #expect(button.title(for: .normal) == "保存中…")
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

@MainActor
private func movement(
    userClassification: UserMovementClassification?
) -> MapMovementLabel {
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
        userClassification: userClassification
    )
}

@MainActor
private func stay() -> MapStayAnnotation {
    let date = Date(timeIntervalSince1970: 0)
    return MapStayAnnotation(
        stayStableID: "stay",
        coordinate: RouteCoordinate(latitude: 35, longitude: 139),
        text: "1分",
        arrivalDate: date,
        departureDate: date.addingTimeInterval(60),
        durationSeconds: 60,
        confidence: .medium,
        isVisibleByAutomaticRule: true
    )
}
