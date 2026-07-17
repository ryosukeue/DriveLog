@testable import DriveLog
import MapKit
import Testing

@MainActor
@Suite("Route map annotation views")
struct RouteMapAnnotationViewTests {
    @Test("scene media renders without a separate media snapshot")
    func sceneMediaDoesNotRequireSnapshot() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        coordinator.addAnnotations(
            scene: MapScene(
                polylines: [], movementLabels: [], stayAnnotations: [],
                mediaAnnotations: [MapMediaAnnotation(
                    localIdentifier: "private-id",
                    mediaType: .photo,
                    coordinate: RouteCoordinate(latitude: 35, longitude: 139)
                )],
                initialRegion: nil
            ),
            to: mapView
        )

        let media = try #require(mapView.annotations.first as? RouteMapPointAnnotation)
        guard case .media = media.kind else {
            Issue.record("Expected a media annotation")
            return
        }
        #expect(media.mediaType == .photo)
    }

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

        #expect(view.displayedCountText == "2枚")
        #expect(view.accessibilityLabel == "2件の写真と動画")
        #expect(view.accessibilityIdentifier == "map.mediaCluster")
        #expect(view.collisionMode == .rectangle)
    }

    @Test("an exact-coordinate cluster opens its media grid")
    func exactCoordinateClusterSelection() {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        let cluster = MKClusterAnnotation(memberAnnotations: [
            point(id: "one", kind: .media, mediaType: .photo),
            point(id: "two", kind: .media, mediaType: .video)
        ])
        var selection: MapPlaceSelection?
        coordinator.onSelectPlace = { selection = $0 }
        let view = MKAnnotationView(annotation: cluster, reuseIdentifier: nil)

        coordinator.mapView(mapView, didSelect: view)

        #expect(selection?.mediaIdentifiers == ["one", "two"])
        #expect(selection?.stayStableIDs == [])
    }

    @Test("a mixed-coordinate cluster also opens its media grid")
    func mixedCoordinateClusterSelection() {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        let cluster = MKClusterAnnotation(memberAnnotations: [
            point(id: "one", kind: .media, mediaType: .photo),
            point(
                id: "two",
                kind: .media,
                mediaType: .video,
                coordinate: CLLocationCoordinate2D(latitude: 35.001, longitude: 139)
            )
        ])
        var selection: MapPlaceSelection?
        coordinator.onSelectPlace = { selection = $0 }
        let view = MKAnnotationView(annotation: cluster, reuseIdentifier: nil)

        coordinator.mapView(mapView, didSelect: view)

        #expect(selection?.mediaIdentifiers == ["one", "two"])
        #expect(selection?.stayStableIDs == [])
    }

    @Test("media absorbs nearby repeated stays into one place summary")
    func mediaStaySummary() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        coordinator.addAnnotations(
            scene: MapScene(
                polylines: [], movementLabels: [],
                stayAnnotations: [stay(id: "first"), stay(id: "second")],
                mediaAnnotations: [MapMediaAnnotation(
                    localIdentifier: "media", mediaType: .photo,
                    coordinate: RouteCoordinate(latitude: 35, longitude: 139)
                )],
                initialRegion: nil
            ),
            to: mapView
        )

        let annotation = try #require(mapView.annotations.first as? RouteMapPointAnnotation)
        #expect(mapView.annotations.count == 1)
        #expect(annotation.kind == .media)
        #expect(annotation.relatedStays.map(\.stayStableID) == ["first", "second"])
        let view = try #require(
            coordinator.mapView(mapView, viewFor: annotation) as? RouteMapMediaAnnotationView
        )
        #expect(view.displayedStayText == "滞在2回・計2分")
        #expect(view.displayPriority == .required)
    }

    @Test("repeated stays without media share one marker")
    func repeatedStayGrouping() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        coordinator.addAnnotations(
            scene: MapScene(
                polylines: [], movementLabels: [],
                stayAnnotations: [stay(id: "first"), stay(id: "second")],
                mediaAnnotations: [], initialRegion: nil
            ),
            to: mapView
        )

        let annotation = try #require(mapView.annotations.first as? RouteMapPointAnnotation)
        #expect(mapView.annotations.count == 1)
        #expect(annotation.relatedStays.count == 2)
        #expect(annotation.labelText == "滞在2回・計2分")
    }

    @Test("stay annotations cluster independently from media")
    func stayClustering() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        let stay = try #require(coordinator.mapView(
            mapView,
            viewFor: point(id: "stay", kind: .stay, label: "5分")
        ))

        #expect(stay.clusteringIdentifier == "stay")
        #expect(stay.collisionMode == .rectangle)
    }

    @Test("a stay-only cluster opens the shared place selection")
    func stayClusterSelection() throws {
        let mapView = MKMapView()
        let coordinator = RouteMapCoordinator()
        let members = [
            point(
                id: "first",
                kind: .stay,
                stay: stay(id: "first"),
                relatedStays: [stay(id: "first")]
            ),
            point(
                id: "second",
                kind: .stay,
                stay: stay(id: "second"),
                relatedStays: [stay(id: "second")]
            )
        ]
        let cluster = MKClusterAnnotation(memberAnnotations: members)
        var selection: MapPlaceSelection?
        coordinator.onSelectPlace = { selection = $0 }
        let view = try #require(coordinator.mapView(mapView, viewFor: cluster))

        coordinator.mapView(mapView, didSelect: view)

        #expect(view is RouteMapStayClusterAnnotationView)
        #expect(selection?.mediaIdentifiers == [])
        #expect(selection?.stayStableIDs == ["first", "second"])
    }

    @Test("movement callout shows only start, end, and average speed")
    func movementCalloutContent() throws {
        let view = RouteMapMovementCalloutView(annotation: nil, reuseIdentifier: nil)
        let timeZone = try #require(TimeZone(identifier: "UTC"))
        let formatter = DayDetailFormatter(timeZone: timeZone)

        view.configure(
            movement: movement(userClassification: .automotive),
            formatter: formatter
        )

        #expect(view.displayedItems == [
            "所要時間 1分", "開始 0:00", "終了 0:01", "平均速度 --"
        ])
        #expect(view.accessibilityLabel == "所要時間 1分、開始 0:00、終了 0:01、平均速度 --")
        #expect(view.accessibilityIdentifier == "map.movementCallout")
        #expect(view.accessibilityTraits.contains(.staticText))
        #expect(view.displayPriority == .required)
        #expect(view.zPriority == .max)
    }

    @Test("movement callout aligns metric titles and values in shared rows")
    func movementCalloutMetricAlignment() {
        let view = RouteMapMetricsView()
        view.frame = CGRect(x: 0, y: 0, width: 344, height: RouteMapMetricsView.preferredHeight)
        view.configure(items: [
            ("所要時間", "45分"),
            ("開始", "10:20"),
            ("終了", "11:05"),
            ("平均速度", "24.5km/h")
        ])
        view.layoutIfNeeded()

        let titleFrames = descendantLabels(
            in: view,
            accessibilityIdentifier: "map.metric.title"
        ).map { view.convert($0.bounds, from: $0) }
        let valueFrames = descendantLabels(
            in: view,
            accessibilityIdentifier: "map.metric.value"
        ).map { view.convert($0.bounds, from: $0) }

        #expect(titleFrames.count == 4)
        #expect(valueFrames.count == 4)
        #expect(sharedMidY(titleFrames))
        #expect(sharedMidY(valueFrames))
        #expect(zip(titleFrames, valueFrames).allSatisfy { pair in
            abs(pair.0.midX - pair.1.midX) < 0.5
        })
        #expect(zip(titleFrames, valueFrames).allSatisfy { pair in
            (pair.1.minY - pair.0.maxY) <= 3
        })
    }

    @Test("stay callout shows time details without correction controls")
    func stayCalloutContent() throws {
        let view = RouteMapStayCalloutView(annotation: nil, reuseIdentifier: nil)
        try view.configure(
            stay: stay(),
            formatter: DayDetailFormatter(timeZone: #require(TimeZone(identifier: "UTC")))
        )

        #expect(view.displayedItems == ["滞在時間 1分", "到着 0:00", "出発 0:01"])
        #expect(view.subviews.contains { $0 is UIButton } == false)
    }
}

@MainActor
private func descendantLabels(
    in view: UIView,
    accessibilityIdentifier: String
) -> [UILabel] {
    view.subviews.flatMap { subview -> [UILabel] in
        let matchingLabel = (subview as? UILabel).flatMap { label in
            label.accessibilityIdentifier == accessibilityIdentifier ? label : nil
        }
        return [matchingLabel].compactMap { $0 } + descendantLabels(
            in: subview,
            accessibilityIdentifier: accessibilityIdentifier
        )
    }
}

private func sharedMidY(_ frames: [CGRect]) -> Bool {
    guard let first = frames.first else { return false }
    return frames.dropFirst().allSatisfy { abs($0.midY - first.midY) < 0.5 }
}

@MainActor
private func point(
    id: String,
    kind: RouteMapPointAnnotation.Kind,
    label: String? = nil,
    mediaType: MediaType? = nil,
    coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 35, longitude: 139),
    stay: MapStayAnnotation? = nil,
    relatedStays: [MapStayAnnotation] = []
) -> RouteMapPointAnnotation {
    RouteMapPointAnnotation(
        id: id,
        coordinate: coordinate,
        kind: kind,
        labelText: label,
        stay: stay,
        mediaType: mediaType,
        relatedStays: relatedStays
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
private func stay(id: String = "stay") -> MapStayAnnotation {
    let date = Date(timeIntervalSince1970: 0)
    return MapStayAnnotation(
        stayStableID: id,
        coordinate: RouteCoordinate(latitude: 35, longitude: 139),
        text: "1分",
        arrivalDate: date,
        departureDate: date.addingTimeInterval(60),
        durationSeconds: 60,
        confidence: .medium,
        isVisibleByAutomaticRule: true
    )
}
