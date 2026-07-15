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
        let visibleStay = makeStay(id: "visible", visible: true, coordinate: coordinate(34, 138))
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
}

private func coordinate(_ latitude: Double, _ longitude: Double) -> RouteCoordinate {
    RouteCoordinate(latitude: latitude, longitude: longitude)
}

private func makeMovement(
    route: [RouteCoordinate],
    label: RouteCoordinate?
) -> MovementSegmentData {
    let date = Date(timeIntervalSince1970: 0)
    return MovementSegmentData(
        stableID: "movement", localDateKey: "2024-01-01", startDate: date,
        endDate: date.addingTimeInterval(60), distanceMeters: 100, durationSeconds: 60,
        estimatedAverageSpeedMetersPerSecond: nil, automaticClassification: .other,
        classificationConfidence: .low, route: route, labelCoordinate: label,
        sourceRawRevision: 1, generatedAt: date
    )
}

private func makeStay(
    id: String,
    visible: Bool,
    coordinate: RouteCoordinate
) -> StaySegmentData {
    let date = Date(timeIntervalSince1970: 0)
    return StaySegmentData(
        stableID: id, localDateKey: "2024-01-01", representativeCoordinate: coordinate,
        estimatedArrivalDate: date, estimatedDepartureDate: date.addingTimeInterval(60),
        durationSeconds: 60, confidence: .medium, source: .combined,
        isVisibleByAutomaticRule: visible, sourceRawRevision: 1, generatedAt: date
    )
}
