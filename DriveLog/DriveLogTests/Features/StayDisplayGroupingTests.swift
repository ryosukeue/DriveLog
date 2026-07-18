@testable import DriveLog
import Foundation
import Testing

@Suite("Stay display grouping")
struct StayDisplayGroupingTests {
    @Test("adjacent stays at the same place become one display group")
    func adjacentStaysAreGrouped() {
        let base = Date(timeIntervalSince1970: 0)
        let first = mapStay(
            id: "first",
            coordinate: coordinateAtMeters(0),
            arrival: base,
            duration: 10 * 60
        )
        let second = mapStay(
            id: "second",
            coordinate: coordinateAtMeters(50),
            arrival: base.addingTimeInterval(10 * 60),
            duration: 10 * 60
        )

        let groups = StayDisplayGrouping().groups(stays: [first, second], movements: [])

        #expect(groups.count == 1)
        #expect(groups[0].memberStableIDs == ["first", "second"])
        #expect(groups[0].arrivalDate == base)
        #expect(groups[0].departureDate == base.addingTimeInterval(20 * 60))
        #expect(groups[0].durationSeconds == 20 * 60)
    }

    @Test("overlapping stays within five minutes are one display group")
    func overlappingStaysAreGrouped() {
        let base = Date(timeIntervalSince1970: 0)
        let first = mapStay(id: "first", arrival: base, duration: 10 * 60)
        let second = mapStay(
            id: "second",
            arrival: base.addingTimeInterval(9 * 60),
            duration: 10 * 60
        )

        let groups = StayDisplayGrouping().groups(stays: [first, second], movements: [])

        #expect(groups.count == 1)
        #expect(groups[0].durationSeconds == TimeInterval(19 * 60))
    }

    @Test("a gap over five minutes remains a separate display group")
    func largeTemporalGapIsNotGrouped() {
        let base = Date(timeIntervalSince1970: 0)
        let first = mapStay(id: "first", arrival: base, duration: 60)
        let second = mapStay(
            id: "second",
            arrival: base.addingTimeInterval(6 * 60 + 1),
            duration: 60
        )

        #expect(
            StayDisplayGrouping().groups(stays: [first, second], movements: []).count == 2
        )
    }

    @Test("a distance over 150 meters remains a separate display group")
    func largeDistanceIsNotGrouped() {
        let base = Date(timeIntervalSince1970: 0)
        let first = mapStay(
            id: "first",
            coordinate: coordinateAtMeters(0),
            arrival: base,
            duration: 60
        )
        let second = mapStay(
            id: "second",
            coordinate: coordinateAtMeters(151),
            arrival: base.addingTimeInterval(60),
            duration: 60
        )

        #expect(
            StayDisplayGrouping().groups(stays: [first, second], movements: []).count == 2
        )
    }

    @Test("a movement crossing the interval prevents display grouping")
    func movementCrossingIntervalIsNotGrouped() {
        let base = Date(timeIntervalSince1970: 0)
        let first = mapStay(id: "first", arrival: base, duration: 5 * 60)
        let second = mapStay(
            id: "second",
            arrival: base.addingTimeInterval(500),
            duration: 5 * 60
        )
        let movement = MapMovementLabel(
            segmentStableID: "movement",
            coordinate: coordinateAtMeters(0),
            text: "",
            startDate: base.addingTimeInterval(350),
            endDate: base.addingTimeInterval(450),
            durationSeconds: 100,
            distanceMeters: 100,
            averageSpeedMetersPerSecond: nil,
            automaticClassification: .other,
            userClassification: nil
        )

        #expect(
            StayDisplayGrouping().groups(stays: [first, second], movements: [movement]).count == 2
        )
    }

    @Test("different local dates are never grouped")
    func differentLocalDatesAreNotGrouped() {
        let base = Date(timeIntervalSince1970: 0)
        let first = displayStay(id: "first", localDateKey: "2026-07-17", arrival: base)
        let second = displayStay(id: "second", localDateKey: "2026-07-18", arrival: base)

        #expect(
            StayDisplayGrouping().groups(stays: [first, second], movements: []).count == 2
        )
    }

    @Test("a display group retains every stable ID and spans its members")
    func groupRetainsStableIDs() {
        let base = Date(timeIntervalSince1970: 0)
        let stays = [
            mapStay(id: "one", arrival: base, duration: 60),
            mapStay(id: "two", arrival: base.addingTimeInterval(60), duration: 60),
            mapStay(id: "three", arrival: base.addingTimeInterval(120), duration: 60)
        ]

        let group = StayDisplayGrouping().groups(stays: stays, movements: []).first

        #expect(group?.memberStableIDs == ["one", "two", "three"])
        #expect(group?.durationSeconds == TimeInterval(3 * 60))
    }

    private func mapStay(
        id: String,
        coordinate: RouteCoordinate = coordinateAtMeters(0),
        arrival: Date,
        duration: TimeInterval
    ) -> MapStayAnnotation {
        MapStayAnnotation(
            stayStableID: id,
            coordinate: coordinate,
            text: "滞在",
            arrivalDate: arrival,
            departureDate: arrival.addingTimeInterval(duration),
            durationSeconds: duration,
            confidence: .medium,
            isVisibleByAutomaticRule: true
        )
    }

    private func displayStay(
        id: String,
        localDateKey: String,
        arrival: Date
    ) -> StayDisplayData {
        StayDisplayData(
            segment: StaySegmentData(
                stableID: id,
                localDateKey: localDateKey,
                representativeCoordinate: coordinateAtMeters(0),
                estimatedArrivalDate: arrival,
                estimatedDepartureDate: arrival.addingTimeInterval(60),
                durationSeconds: 60,
                confidence: .medium,
                source: .combined,
                isVisibleByAutomaticRule: true,
                sourceRawRevision: 1,
                generatedAt: arrival
            ),
            overrideAction: nil
        )
    }
}

private func coordinateAtMeters(_ distance: Double) -> RouteCoordinate {
    RouteCoordinate(latitude: 0, longitude: distance / 6_371_000 * 180 / .pi)
}
