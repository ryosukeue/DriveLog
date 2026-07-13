@testable import DriveLog
import Foundation
import Testing

@Suite("Default day processor override reconnection")
@MainActor
struct DefaultDayProcessorOverrideTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("prioritizes an exact stay override without changing the automatic value")
    func exactStayOverride() async throws {
        let stayOverride = StayOverrideData(
            overrideKey: "stay-override",
            targetStableID: "fixed-stay-id",
            localDateKey: "2024-01-01",
            originalArrivalDate: baseDate.addingTimeInterval(50000),
            originalDepartureDate: baseDate.addingTimeInterval(60000),
            originalCoordinate: coordinate(eastMeters: 50000),
            action: .hide,
            createdAt: baseDate,
            updatedAt: baseDate
        )
        let processor = DefaultDayProcessor(
            clock: OverrideFixedClock(now: baseDate.addingTimeInterval(10000)),
            stableIDGenerator: OverrideFixedStableIDGenerator()
        )

        let result = try await processor.process(
            localDateKey: "2024-01-01",
            rawEvents: rawEvents(
                locations: longStayLocations(),
                stays: [stayOverride]
            ),
            mediaCount: 0,
            rawRevision: 4
        )

        #expect(result.stays.first?.stableID == "fixed-stay-id")
        #expect(result.stays.first?.isVisibleByAutomaticRule == true)
        #expect(result.aggregate.staySegmentCount == 0)
    }

    @Test("rejects one override when multiple approximate stays match")
    func ambiguousStayOverride() async throws {
        let locations = [
            location(eastMeters: 0, seconds: 0),
            location(eastMeters: 100, seconds: 120),
            location(eastMeters: 100, seconds: 420),
            location(eastMeters: 200, seconds: 540),
            location(eastMeters: 300, seconds: 660),
            location(eastMeters: 300, seconds: 960),
            location(eastMeters: 400, seconds: 1080)
        ]
        let stayOverride = StayOverrideData(
            overrideKey: "stay-override",
            targetStableID: "previous-stay-id",
            localDateKey: "2024-01-01",
            originalArrivalDate: baseDate.addingTimeInterval(390),
            originalDepartureDate: baseDate.addingTimeInterval(690),
            originalCoordinate: coordinate(eastMeters: 200),
            action: .hide,
            createdAt: baseDate,
            updatedAt: baseDate
        )
        let visits = [
            visit(eastMeters: 100, arrival: 121, departure: 419),
            visit(eastMeters: 300, arrival: 661, departure: 959)
        ]
        let processor = DefaultDayProcessor(
            clock: OverrideFixedClock(now: baseDate.addingTimeInterval(10000))
        )

        let result = try await processor.process(
            localDateKey: "2024-01-01",
            rawEvents: RawDayEvents(
                locations: locations,
                motions: [],
                visits: visits,
                classificationOverrides: [],
                stayOverrides: [stayOverride]
            ),
            mediaCount: 0,
            rawRevision: 4
        )

        let allAutomaticallyVisible = result.stays.allSatisfy(\.isVisibleByAutomaticRule)
        #expect(result.stays.count == 2)
        #expect(allAutomaticallyVisible)
        #expect(result.aggregate.staySegmentCount == 2)
    }

    private func longStayLocations() -> [LocationEventData] {
        [
            location(eastMeters: 0, seconds: 0),
            location(eastMeters: 100, seconds: 120),
            location(eastMeters: 100, seconds: 7320),
            location(eastMeters: 200, seconds: 7440)
        ]
    }

    private func rawEvents(
        locations: [LocationEventData],
        stays: [StayOverrideData]
    ) -> RawDayEvents {
        RawDayEvents(
            locations: locations,
            motions: [],
            visits: [],
            classificationOverrides: [],
            stayOverrides: stays
        )
    }

    private func location(eastMeters: Double, seconds: TimeInterval) -> LocationEventData {
        LocationEventData(
            latitude: 0,
            longitude: coordinate(eastMeters: eastMeters).longitude,
            timestamp: baseDate.addingTimeInterval(seconds),
            horizontalAccuracy: 10,
            speedMetersPerSecond: nil,
            createdAt: baseDate.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }

    private func visit(
        eastMeters: Double,
        arrival: TimeInterval,
        departure: TimeInterval
    ) -> VisitEventData {
        VisitEventData(
            latitude: 0,
            longitude: coordinate(eastMeters: eastMeters).longitude,
            arrivalDate: baseDate.addingTimeInterval(arrival),
            departureDate: baseDate.addingTimeInterval(departure),
            horizontalAccuracy: 10,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }

    private func coordinate(eastMeters: Double) -> RouteCoordinate {
        RouteCoordinate(latitude: 0, longitude: eastMeters / 6_371_000 * 180 / .pi)
    }
}

private struct OverrideFixedClock: Clock {
    let now: Date
}

private struct OverrideFixedStableIDGenerator: StableIDGenerating {
    func movementSegmentID(
        localDateKey _: String,
        startDate _: Date,
        endDate _: Date
    ) -> String {
        "fixed-movement-id"
    }

    func staySegmentID(
        localDateKey _: String,
        arrivalDate _: Date,
        departureDate _: Date,
        latitude _: Double,
        longitude _: Double
    ) -> String {
        "fixed-stay-id"
    }
}
