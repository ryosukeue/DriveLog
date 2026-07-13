@testable import DriveLog
import Foundation
import Testing

@MainActor
@Suite("Media placement calculator")
struct MediaPlacementCalculatorTests {
    private let calculator = MediaPlacementCalculator()

    @Test("places only located media in input order")
    func locatedMediaOnly() {
        let placements = calculator.place(
            assets: [
                asset(id: "first", coordinate: coordinate(northMeters: 1000)),
                asset(id: "missing", coordinate: nil),
                asset(id: "last", coordinate: coordinate(northMeters: 2000))
            ],
            movements: []
        )

        #expect(placements.map(\.assetIdentifier) == ["first", "last"])
        #expect(placements.map(\.coordinate) == [
            coordinate(northMeters: 1000),
            coordinate(northMeters: 2000)
        ])
        #expect(placements.allSatisfy { $0.relatedMovementStableID == nil })
    }

    @Test("associates single point routes within and at 500 meters")
    func boundary() {
        let routePoint = coordinate(northMeters: 0)
        let movement = movement(id: "route", route: [routePoint])
        let placements = calculator.place(
            assets: [
                asset(id: "inside", coordinate: coordinate(northMeters: 499.9)),
                asset(id: "boundary", coordinate: coordinate(northMeters: 500))
            ],
            movements: [movement]
        )

        #expect(placements.map(\.relatedMovementStableID) == ["route", "route"])
    }

    @Test("places media beyond 500 meters without an association")
    func beyondBoundary() {
        let placements = calculator.place(
            assets: [asset(id: "far", coordinate: coordinate(northMeters: 500.1))],
            movements: [movement(id: "route", route: [coordinate(northMeters: 0)])]
        )

        #expect(placements.first?.coordinate == coordinate(northMeters: 500.1))
        #expect(placements.first?.relatedMovementStableID == nil)
    }

    @Test("uses the closest point on a polyline segment")
    func polylineDistance() {
        let movement = movement(
            id: "crossing",
            route: [coordinate(eastMeters: -1000), coordinate(eastMeters: 1000)]
        )

        let placement = calculator.place(
            assets: [asset(id: "near-middle", coordinate: coordinate(northMeters: 100))],
            movements: [movement]
        ).first

        #expect(placement?.relatedMovementStableID == "crossing")
    }

    @Test("selects the nearest route before considering time")
    func nearestRoute() {
        let asset = asset(
            id: "asset",
            coordinate: coordinate(northMeters: 0),
            creationDate: date(150)
        )
        let nearestOutsideTime = movement(
            id: "nearest",
            start: 0,
            end: 100,
            route: [coordinate(northMeters: 100)]
        )
        let fartherInsideTime = movement(
            id: "farther",
            start: 140,
            end: 200,
            route: [coordinate(northMeters: 200)]
        )

        let placement = calculator.place(
            assets: [asset],
            movements: [fartherInsideTime, nearestOutsideTime]
        ).first

        #expect(placement?.relatedMovementStableID == "nearest")
    }

    @Test("uses capture time for equal-distance routes")
    func timeTieBreak() {
        let capturedAt = date(150)
        let sharedRoute = [coordinate(northMeters: 100)]
        let outside = movement(id: "a-outside", start: 0, end: 100, route: sharedRoute)
        let inside = movement(id: "z-inside", start: 140, end: 200, route: sharedRoute)
        let nearestInTime = movement(
            id: "z-nearest-time",
            start: 0,
            end: 100,
            route: sharedRoute
        )
        let fartherInTime = movement(
            id: "a-farther-time",
            start: 300,
            end: 400,
            route: sharedRoute
        )

        let insideResult = calculator.place(
            assets: [asset(id: "inside", coordinate: coordinate(), creationDate: capturedAt)],
            movements: [outside, inside]
        )
        let nearestResult = calculator.place(
            assets: [asset(id: "nearest", coordinate: coordinate(), creationDate: capturedAt)],
            movements: [fartherInTime, nearestInTime]
        )

        #expect(insideResult.first?.relatedMovementStableID == "z-inside")
        #expect(nearestResult.first?.relatedMovementStableID == "z-nearest-time")
    }

    @Test("uses stable identifier when distance and time are tied")
    func deterministicTieBreak() {
        let route = [coordinate(northMeters: 100)]
        let laterID = movement(id: "z-route", route: route)
        let earlierID = movement(id: "a-route", route: route)
        let empty = movement(id: "empty", route: [])

        let withDate = calculator.place(
            assets: [asset(id: "dated", coordinate: coordinate(), creationDate: date(50))],
            movements: [empty, laterID, earlierID]
        )
        let withoutDate = calculator.place(
            assets: [asset(id: "undated", coordinate: coordinate(), creationDate: nil)],
            movements: [laterID, earlierID]
        )

        #expect(withDate.first?.relatedMovementStableID == "a-route")
        #expect(withoutDate.first?.relatedMovementStableID == "a-route")
    }
}

private let earthRadiusMeters = 6_371_000.0

@MainActor
private func coordinate(
    northMeters: Double = 0,
    eastMeters: Double = 0
) -> RouteCoordinate {
    RouteCoordinate(
        latitude: northMeters / earthRadiusMeters * 180 / .pi,
        longitude: eastMeters / earthRadiusMeters * 180 / .pi
    )
}

@MainActor
private func asset(
    id: String,
    coordinate: RouteCoordinate?,
    creationDate: Date? = date(50)
) -> MediaAssetReference {
    MediaAssetReference(
        localIdentifier: id,
        mediaType: .photo,
        creationDate: creationDate,
        location: coordinate,
        durationSeconds: nil,
        isScreenshot: false,
        isScreenRecording: false
    )
}

@MainActor
private func movement(
    id: String,
    start: TimeInterval = 0,
    end: TimeInterval = 100,
    route: [RouteCoordinate]
) -> MovementSegmentData {
    MovementSegmentData(
        stableID: id,
        localDateKey: "2024-01-01",
        startDate: date(start),
        endDate: date(end),
        distanceMeters: 1000,
        durationSeconds: end - start,
        estimatedAverageSpeedMetersPerSecond: nil,
        automaticClassification: .other,
        classificationConfidence: .low,
        route: route,
        labelCoordinate: nil,
        sourceRawRevision: 1,
        generatedAt: date(500)
    )
}

private func date(_ seconds: TimeInterval) -> Date {
    Date(timeIntervalSince1970: seconds)
}
