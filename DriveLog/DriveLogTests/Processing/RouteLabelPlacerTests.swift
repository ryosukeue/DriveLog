@testable import DriveLog
import Foundation
import Testing

@Suite("Route label placer")
struct RouteLabelPlacerTests {
    private let placer = RouteLabelPlacer(rules: ProcessingConfiguration.mvp.route)

    @Test("places the label at half of route distance instead of the middle index")
    func distanceMidpoint() {
        let route = [coordinate(0), coordinate(100), coordinate(1000)]
        let label = placer.makeLabel(for: segment(route: route), occupiedCoordinates: [])

        #expect(abs(label.coordinate.longitude - coordinate(500).longitude) < 0.000_000_1)
    }

    @Test("uses fallback positions in configured order")
    func fallbackOrder() {
        let segment = segment(route: [coordinate(0), coordinate(1000)])
        let primary = placer.makeLabel(for: segment, occupiedCoordinates: []).coordinate
        let forty = placer.makeLabel(for: segment, occupiedCoordinates: [primary]).coordinate
        let fortyFive = placer.makeLabel(for: segment, occupiedCoordinates: [primary, forty]).coordinate
        let fiftyFive = placer.makeLabel(
            for: segment,
            occupiedCoordinates: [primary, forty, fortyFive]
        ).coordinate
        let sixty = placer.makeLabel(
            for: segment,
            occupiedCoordinates: [primary, forty, fortyFive, fiftyFive]
        ).coordinate

        #expect(close(forty, coordinate(400)))
        #expect(close(fortyFive, coordinate(450)))
        #expect(close(fiftyFive, coordinate(550)))
        #expect(close(sixty, coordinate(600)))
    }

    @Test("returns the primary position when every candidate is occupied")
    func allCandidatesOccupied() {
        let segment = segment(route: [coordinate(0), coordinate(1000)])
        var occupied: [RouteCoordinate] = []
        for _ in 0 ..< 5 {
            occupied.append(placer.makeLabel(for: segment, occupiedCoordinates: occupied).coordinate)
        }
        let label = placer.makeLabel(for: segment, occupiedCoordinates: occupied)

        #expect(label.coordinate == occupied[0])
    }

    @Test("handles a short route and a single point")
    func sparseRoutes() {
        let short = placer.makeLabel(
            for: segment(route: [coordinate(0), coordinate(10)]),
            occupiedCoordinates: []
        )
        let singleCoordinate = coordinate(42)
        let single = placer.makeLabel(
            for: segment(route: [singleCoordinate]),
            occupiedCoordinates: []
        )

        #expect(close(short.coordinate, coordinate(5)))
        #expect(single.coordinate == singleCoordinate)
    }

    @Test("formats segment identifier duration and distance")
    func labelText() {
        let meters = placer.makeLabel(
            for: segment(route: [coordinate(0)], distance: 850, duration: 32 * 60),
            occupiedCoordinates: []
        )
        let kilometers = placer.makeLabel(
            for: segment(route: [coordinate(0)], distance: 54800, duration: 72 * 60),
            occupiedCoordinates: []
        )

        #expect(meters.movementSegmentID == "segment-id")
        #expect(meters.text == "32分・850m")
        #expect(kilometers.text == "1時間12分・54.8km")
    }

    private func segment(
        route: [RouteCoordinate],
        distance: Double = 1000,
        duration: TimeInterval = 600
    ) -> MovementSegmentData {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        return MovementSegmentData(
            stableID: "segment-id",
            localDateKey: "2024-01-01",
            startDate: date,
            endDate: date.addingTimeInterval(duration),
            distanceMeters: distance,
            durationSeconds: duration,
            estimatedAverageSpeedMetersPerSecond: nil,
            automaticClassification: .other,
            classificationConfidence: .low,
            route: route,
            labelCoordinate: nil,
            sourceRawRevision: 1,
            generatedAt: date
        )
    }

    private func coordinate(_ eastMeters: Double) -> RouteCoordinate {
        RouteCoordinate(latitude: 0, longitude: eastMeters / 6_371_000 * 180 / .pi)
    }

    private func close(_ lhs: RouteCoordinate, _ rhs: RouteCoordinate) -> Bool {
        abs(lhs.latitude - rhs.latitude) < 0.000_000_1 &&
            abs(lhs.longitude - rhs.longitude) < 0.000_000_1
    }
}
