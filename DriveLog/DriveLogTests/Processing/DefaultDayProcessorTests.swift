@testable import DriveLog
import Foundation
import Testing

@Suite("Default day processor")
@MainActor
struct DefaultDayProcessorTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("integrates movement classification route label and summary")
    func movementPipeline() async throws {
        let generatedAt = baseDate.addingTimeInterval(10000)
        let processor = makeProcessor(now: generatedAt)
        let locations = [
            location(eastMeters: 0, seconds: 0),
            location(eastMeters: 600, seconds: 120),
            location(eastMeters: 1200, seconds: 240)
        ]
        let motion = MotionEventData(
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(240),
            isAutomotive: false,
            isWalking: true,
            isRunning: false,
            isCycling: false,
            isStationary: false,
            isUnknown: false,
            confidence: .high,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )

        let result = try await processor.process(
            localDateKey: "2024-01-01",
            rawEvents: RawDayEvents(
                locations: locations,
                motions: [motion],
                visits: [],
                classificationOverrides: [],
                stayOverrides: []
            ),
            mediaCount: 3,
            rawRevision: 7
        )

        let movement = try #require(result.movements.first)
        #expect(result.movements.count == 1)
        #expect(movement.automaticClassification == .walkingLike)
        #expect(movement.route.count == 3)
        #expect(movement.labelCoordinate != nil)
        #expect(movement.sourceRawRevision == 7)
        #expect(movement.generatedAt == generatedAt)
        #expect(!movement.stableID.isEmpty)
        #expect(result.aggregate.totalDistanceMeters >= 1199.9)
        #expect(result.aggregate.hasValidMovement)
        #expect(result.aggregate.mediaCountCache == 3)
        #expect(result.aggregate.generatedAt == generatedAt)
    }

    @Test("reapplies one approximate hide override to a stay")
    func approximateStayOverride() async throws {
        let locations = [
            location(eastMeters: 0, seconds: 0),
            location(eastMeters: 100, seconds: 120),
            location(eastMeters: 100, seconds: 7320),
            location(eastMeters: 200, seconds: 7440)
        ]
        let stayOverride = StayOverrideData(
            overrideKey: "stay-override",
            targetStableID: "previous-stable-id",
            localDateKey: "2024-01-01",
            originalArrivalDate: baseDate.addingTimeInterval(180),
            originalDepartureDate: baseDate.addingTimeInterval(7260),
            originalCoordinate: coordinate(eastMeters: 100),
            action: .hide,
            createdAt: baseDate,
            updatedAt: baseDate
        )

        let result = try await makeProcessor().process(
            localDateKey: "2024-01-01",
            rawEvents: RawDayEvents(
                locations: locations,
                motions: [],
                visits: [],
                classificationOverrides: [],
                stayOverrides: [stayOverride]
            ),
            mediaCount: 0,
            rawRevision: 4
        )

        let stay = try #require(result.stays.first)
        #expect(result.stays.count == 1)
        #expect(stay.isVisibleByAutomaticRule)
        #expect(stay.sourceRawRevision == 4)
        #expect(result.aggregate.staySegmentCount == 0)
    }

    @Test("returns deterministic empty results for empty one point and another day")
    func sparseAndDayBoundaryInputs() async throws {
        let processor = makeProcessor()
        let empty = try await processor.process(
            localDateKey: "2024-01-01",
            rawEvents: .empty,
            mediaCount: 0,
            rawRevision: 1
        )
        let sparse = RawDayEvents(
            locations: [
                location(eastMeters: 0, seconds: 0),
                location(eastMeters: 1000, seconds: 120, day: "2024-01-02")
            ],
            motions: [],
            visits: [],
            classificationOverrides: [],
            stayOverrides: []
        )
        let first = try await processor.process(
            localDateKey: "2024-01-01", rawEvents: sparse, mediaCount: 0, rawRevision: 2
        )
        let second = try await processor.process(
            localDateKey: "2024-01-01", rawEvents: sparse, mediaCount: 0, rawRevision: 2
        )

        #expect(empty.movements.isEmpty)
        #expect(empty.stays.isEmpty)
        #expect(first.movements.isEmpty)
        #expect(first.aggregate.locationRecordCount == 1)
        #expect(first.aggregate.totalDistanceMeters == second.aggregate.totalDistanceMeters)
        #expect(first.aggregate.generatedAt == second.aggregate.generatedAt)
    }

    @Test("counts all rejected locations without failing")
    func allRejected() async throws {
        let invalid = LocationEventData(
            latitude: 100,
            longitude: 139,
            timestamp: baseDate,
            horizontalAccuracy: 10,
            speedMetersPerSecond: nil,
            createdAt: baseDate,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )

        let result = try await makeProcessor().process(
            localDateKey: "2024-01-01",
            rawEvents: RawDayEvents(
                locations: [invalid], motions: [], visits: [],
                classificationOverrides: [], stayOverrides: []
            ),
            mediaCount: 0,
            rawRevision: 1
        )

        #expect(result.aggregate.locationRecordCount == 0)
        #expect(result.aggregate.rejectedLocationCount == 1)
        #expect(!result.aggregate.hasValidMovement)
    }

    @Test("propagates task cancellation")
    func cancellation() async {
        let processor = makeProcessor()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await processor.process(
                localDateKey: "2024-01-01",
                rawEvents: .empty,
                mediaCount: 0,
                rawRevision: 1
            )
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    private func makeProcessor(now: Date? = nil) -> DefaultDayProcessor {
        DefaultDayProcessor(clock: FixedClock(now: now ?? baseDate.addingTimeInterval(10000)))
    }

    private func location(
        eastMeters: Double,
        seconds: TimeInterval,
        day: String = "2024-01-01"
    ) -> LocationEventData {
        LocationEventData(
            latitude: 0,
            longitude: coordinate(eastMeters: eastMeters).longitude,
            timestamp: baseDate.addingTimeInterval(seconds),
            horizontalAccuracy: 10,
            speedMetersPerSecond: nil,
            createdAt: baseDate.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: day
        )
    }

    private func coordinate(eastMeters: Double) -> RouteCoordinate {
        RouteCoordinate(latitude: 0, longitude: eastMeters / 6_371_000 * 180 / .pi)
    }
}

private struct FixedClock: Clock {
    let now: Date
}
