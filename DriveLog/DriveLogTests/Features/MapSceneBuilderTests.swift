@testable import DriveLog
import Foundation
import Testing

@Suite("Map scene builder")
struct MapSceneBuilderTests {
    private let builder = MapSceneBuilder()

    @Test("returns an empty scene")
    func empty() {
        #expect(builder.build(movements: [], stays: [], media: []) == .empty)
    }

    @Test("builds route labels visible stays and media")
    func content() throws {
        let movement = makeMovement(
            route: [coordinate(35, 139), coordinate(36, 141)],
            label: coordinate(35.5, 140)
        )
        let visibleStay = makeStay(
            id: "visible", visible: true, coordinate: coordinate(34, 138), arrival: 10000
        )
        let hiddenStay = makeStay(id: "hidden", visible: false, coordinate: coordinate(40, 145))
        let media = MediaPlacement(
            assetIdentifier: "asset", mediaType: .video, coordinate: coordinate(37, 142),
            relatedMovementStableID: movement.stableID
        )

        let scene = builder.build(
            movements: [movement],
            stays: [visibleStay, hiddenStay],
            media: [media]
        )

        try expectContent(scene, movement: movement, visibleStay: visibleStay)
    }

    private func expectContent(
        _ scene: MapScene,
        movement: MovementSegmentData,
        visibleStay: StaySegmentData
    ) throws {
        #expect(scene.polylines == [
            MapPolyline(segmentStableID: movement.stableID, coordinates: movement.route)
        ])
        #expect(scene.movementLabels == [
            MapMovementLabel(
                segmentStableID: movement.stableID,
                coordinate: coordinate(35.5, 140),
                text: "1分・0.1km",
                startDate: movement.startDate,
                endDate: movement.endDate,
                durationSeconds: movement.durationSeconds,
                distanceMeters: movement.distanceMeters,
                averageSpeedMetersPerSecond: movement.estimatedAverageSpeedMetersPerSecond,
                automaticClassification: movement.automaticClassification,
                userClassification: nil
            )
        ])
        #expect(scene.stayAnnotations == [
            MapStayAnnotation(
                stayStableID: "visible",
                coordinate: coordinate(34, 138),
                text: "1分",
                arrivalDate: visibleStay.estimatedArrivalDate,
                departureDate: visibleStay.estimatedDepartureDate,
                durationSeconds: visibleStay.durationSeconds,
                confidence: visibleStay.confidence,
                isVisibleByAutomaticRule: true
            )
        ])
        #expect(scene.mediaAnnotations == [
            MapMediaAnnotation(
                localIdentifier: "asset", mediaType: .video, coordinate: coordinate(37, 142)
            )
        ])
        let region = try #require(scene.initialRegion)
        #expect(region.center == coordinate(35.5, 140))
        #expect(abs(region.latitudeDelta - 3.6) < 0.000_001)
        #expect(abs(region.longitudeDelta - 4.8) < 0.000_001)
    }

    @Test("uses a minimum region for one coordinate")
    func singleCoordinate() throws {
        let scene = builder.build(
            movements: [makeMovement(route: [coordinate(35, 139)], label: nil)],
            stays: [],
            media: []
        )

        let region = try #require(scene.initialRegion)
        #expect(region.center == coordinate(35, 139))
        #expect(region.latitudeDelta == 0.01)
        #expect(region.longitudeDelta == 0.01)
    }

    @Test("omits empty routes and missing labels")
    func omittedValues() {
        let scene = builder.build(
            movements: [makeMovement(route: [], label: nil)],
            stays: [],
            media: []
        )

        #expect(scene.polylines.isEmpty)
        #expect(scene.movementLabels.isEmpty)
        #expect(scene.initialRegion == nil)
    }

    @Test("connects display route to nearby preceding and following stays")
    func connectsNearbyStays() throws {
        let route = [coordinateAtMeters(0), coordinateAtMeters(200)]
        let movement = makeMovement(
            route: route,
            label: route[0],
            start: 100,
            duration: 100
        )
        let preceding = makeStay(
            id: "preceding",
            visible: true,
            coordinate: coordinateAtMeters(-50),
            arrival: 0,
            duration: 98
        )
        let following = makeStay(
            id: "following",
            visible: true,
            coordinate: coordinateAtMeters(250),
            arrival: 202,
            duration: 60
        )

        let scene = builder.build(
            movements: [movement],
            stays: [preceding, following],
            media: []
        )

        let polyline = try #require(scene.polylines.first)
        #expect(polyline.coordinates == [
            preceding.representativeCoordinate,
            route[0],
            route[1],
            following.representativeCoordinate
        ])
        #expect(scene.movementLabels.first?.distanceMeters == movement.distanceMeters)
        #expect(scene.movementLabels.first?.durationSeconds == movement.durationSeconds)
    }

    @Test("connects display route to temporally adjacent stays regardless of distance")
    func connectsTemporallyAdjacentDistantStays() throws {
        let route = [coordinateAtMeters(0), coordinateAtMeters(200)]
        let movement = makeMovement(route: route, label: nil, start: 1000, duration: 100)
        let preceding = makeStay(
            id: "preceding", visible: true, coordinate: coordinateAtMeters(-1000),
            arrival: 900, duration: 98
        )
        let following = makeStay(
            id: "following", visible: true, coordinate: coordinateAtMeters(1000),
            arrival: 1102, duration: 60
        )

        let scene = builder.build(
            movements: [movement], stays: [preceding, following], media: []
        )

        let polyline = try #require(scene.polylines.first)
        #expect(polyline.coordinates == [
            preceding.representativeCoordinate,
            route[0],
            route[1],
            following.representativeCoordinate
        ])
    }

    @Test("connects when a route endpoint falls inside a stay interval")
    func connectsEndpointInsideStayInterval() throws {
        let route = [coordinateAtMeters(0), coordinateAtMeters(200)]
        let movement = makeMovement(route: route, label: nil, start: 1000, duration: 100)
        let preceding = makeStay(
            id: "preceding", visible: true, coordinate: coordinateAtMeters(-1000),
            arrival: 0, duration: 1400
        )
        let following = makeStay(
            id: "following", visible: true, coordinate: coordinateAtMeters(1000),
            arrival: 600, duration: 1000
        )

        let scene = builder.build(
            movements: [movement], stays: [preceding, following], media: []
        )

        let polyline = try #require(scene.polylines.first)
        #expect(polyline.coordinates == [
            preceding.representativeCoordinate,
            route[0],
            route[1],
            following.representativeCoordinate
        ])
    }

    @Test("does not connect display route to stale or hidden stays")
    func rejectsStaleOrHiddenStayConnections() throws {
        let route = [coordinateAtMeters(0), coordinateAtMeters(200)]
        let movement = makeMovement(route: route, label: nil, start: 1000, duration: 100)
        let distant = makeStay(
            id: "distant", visible: true, coordinate: coordinateAtMeters(-1000),
            arrival: 2000, duration: 98
        )
        let stale = makeStay(
            id: "stale",
            visible: true,
            coordinate: coordinateAtMeters(250),
            arrival: 1401,
            duration: 60
        )
        let hidden = makeStay(
            id: "hidden",
            visible: false,
            coordinate: coordinateAtMeters(250),
            arrival: 1102,
            duration: 60
        )

        let scene = builder.build(
            movements: [movement],
            stays: [distant, stale, hidden],
            media: []
        )

        let polyline = try #require(scene.polylines.first)
        #expect(polyline.coordinates == route)
    }
}

private func coordinate(_ latitude: Double, _ longitude: Double) -> RouteCoordinate {
    RouteCoordinate(latitude: latitude, longitude: longitude)
}

private func coordinateAtMeters(_ distance: Double) -> RouteCoordinate {
    coordinate(0, distance / 6_371_000 * 180 / .pi)
}

private func makeMovement(
    route: [RouteCoordinate],
    label: RouteCoordinate?,
    start: TimeInterval = 0,
    duration: TimeInterval = 60
) -> MovementSegmentData {
    let date = Date(timeIntervalSince1970: start)
    return MovementSegmentData(
        stableID: "movement", localDateKey: "2024-01-01", startDate: date,
        endDate: date.addingTimeInterval(duration), distanceMeters: 100,
        durationSeconds: duration,
        estimatedAverageSpeedMetersPerSecond: nil, automaticClassification: .other,
        classificationConfidence: .low, route: route, labelCoordinate: label,
        sourceRawRevision: 1, generatedAt: date
    )
}

private func makeStay(
    id: String,
    visible: Bool,
    coordinate: RouteCoordinate,
    arrival: TimeInterval = 0,
    duration: TimeInterval = 60
) -> StaySegmentData {
    let date = Date(timeIntervalSince1970: arrival)
    return StaySegmentData(
        stableID: id, localDateKey: "2024-01-01", representativeCoordinate: coordinate,
        estimatedArrivalDate: date, estimatedDepartureDate: date.addingTimeInterval(duration),
        durationSeconds: duration, confidence: .medium, source: .combined,
        isVisibleByAutomaticRule: visible, sourceRawRevision: 1, generatedAt: date
    )
}
