@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Override integration")
@MainActor
struct OverrideIntegrationTests {
    private let day = "2024-01-01"
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("reconnects a classification override after the movement stable ID changes")
    func classificationReprocessing() async throws {
        let fixture = try OverrideFixture(now: baseDate.addingTimeInterval(20000))
        try await fixture.saveLocations(points: [(0, 0), (600, 120), (1200, 240)])
        _ = try await fixture.process.execute(localDateKey: day)
        let original = try #require(try await fixture.derived.movementSegments(for: day).first)
        let storedOverride = ClassificationOverrideData(
            overrideKey: "\(day)|\(original.stableID)",
            targetStableID: original.stableID,
            localDateKey: day,
            originalStartDate: original.startDate,
            originalEndDate: original.endDate,
            userClassification: .train,
            createdAt: baseDate,
            updatedAt: baseDate
        )
        try await fixture.overrides.upsertClassificationOverride(storedOverride)

        try await fixture.saveLocations(points: [(1800, 360)])
        _ = try await fixture.process.execute(localDateKey: day)
        let updated = try #require(try await fixture.derived.movementSegments(for: day).first)
        let detail = try await fixture.loadDetail.execute(localDateKey: day)

        #expect(updated.stableID != original.stableID)
        #expect(detail.movements.first?.segment.stableID == updated.stableID)
        #expect(detail.movements.first?.userClassification == .train)
        #expect(try await fixture.overrides.classificationOverrides(for: day) == [storedOverride])
    }

    @Test("reconnects a stay override while preserving its automatic value")
    func stayReprocessing() async throws {
        let fixture = try OverrideFixture(now: baseDate.addingTimeInterval(20000))
        try await fixture.saveLocations(points: [
            (0, 0), (100, 120), (100, 7320), (200, 7440)
        ])
        _ = try await fixture.process.execute(localDateKey: day)
        let original = try #require(try await fixture.derived.staySegments(for: day).first)
        let storedOverride = StayOverrideData(
            overrideKey: "\(day)|\(original.stableID)",
            targetStableID: original.stableID,
            localDateKey: day,
            originalArrivalDate: original.estimatedArrivalDate,
            originalDepartureDate: original.estimatedDepartureDate,
            originalCoordinate: original.representativeCoordinate,
            action: .hide,
            createdAt: baseDate,
            updatedAt: baseDate
        )
        try await fixture.overrides.upsertStayOverride(storedOverride)

        try await fixture.saveLocations(points: [(100, 180)])
        let result = try await fixture.process.execute(localDateKey: day)
        let updated = try #require(try await fixture.derived.staySegments(for: day).first)
        let detail = try await fixture.loadDetail.execute(localDateKey: day)

        #expect(updated.stableID != original.stableID)
        #expect(updated.isVisibleByAutomaticRule)
        #expect(result.aggregate.staySegmentCount == 0)
        #expect(detail.stays.first?.overrideAction == .hide)
        #expect(detail.mapScene.stayAnnotations.isEmpty)
        #expect(try await fixture.overrides.stayOverrides(for: day) == [storedOverride])
    }

    @Test("rejects one stay override when two approximate candidates exist")
    func ambiguousStayReconnection() async throws {
        let fixture = try OverrideFixture(now: baseDate.addingTimeInterval(20000))
        try await fixture.saveLocations(points: [
            (0, 0), (100, 120), (100, 420), (200, 540),
            (300, 660), (300, 960), (400, 1080)
        ])
        try await fixture.saveVisit(eastMeters: 100, arrival: 121, departure: 419)
        try await fixture.saveVisit(eastMeters: 300, arrival: 661, departure: 959)
        let storedOverride = StayOverrideData(
            overrideKey: "\(day)|previous",
            targetStableID: "previous",
            localDateKey: day,
            originalArrivalDate: baseDate.addingTimeInterval(390),
            originalDepartureDate: baseDate.addingTimeInterval(690),
            originalCoordinate: coordinate(eastMeters: 200),
            action: .hide,
            createdAt: baseDate,
            updatedAt: baseDate
        )
        try await fixture.overrides.upsertStayOverride(storedOverride)

        let result = try await fixture.process.execute(localDateKey: day)
        let detail = try await fixture.loadDetail.execute(localDateKey: day)

        #expect(result.stays.count == 2)
        #expect(result.aggregate.staySegmentCount == 2)
        #expect(detail.stays.map(\.overrideAction) == [nil, nil])
        #expect(detail.mapScene.stayAnnotations.count == 2)
        #expect(try await fixture.overrides.stayOverrides(for: day) == [storedOverride])
    }

    private func coordinate(eastMeters: Double) -> RouteCoordinate {
        RouteCoordinate(latitude: 0, longitude: eastMeters / 6_371_000 * 180 / .pi)
    }
}

@MainActor
private struct OverrideFixture {
    let raw: SwiftDataRawEventRepository
    let overrides: SwiftDataOverrideRepository
    let derived: SwiftDataDerivedDataRepository
    let process: DefaultProcessDayUseCase
    let loadDetail: DefaultLoadDayDetailUseCase
    private let now: Date
    private let day = "2024-01-01"

    init(now: Date) throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let clock = OverrideIntegrationClock(now: now)
        let state = SwiftDataProcessingStateRepository(modelContainer: container, clock: clock)
        raw = SwiftDataRawEventRepository(modelContainer: container, clock: clock)
        overrides = SwiftDataOverrideRepository(modelContainer: container)
        derived = SwiftDataDerivedDataRepository(modelContainer: container)
        self.now = now
        process = DefaultProcessDayUseCase(
            stateRepository: state,
            rawRepository: raw,
            overrideRepository: overrides,
            derivedRepository: derived,
            processor: DefaultDayProcessor(clock: clock),
            clock: clock,
            logger: OverrideIntegrationLogger()
        )
        loadDetail = DefaultLoadDayDetailUseCase(
            derivedRepository: derived,
            overrideRepository: overrides,
            processingStateRepository: state,
            mediaCacheRepository: SwiftDataMediaCacheRepository(modelContainer: container),
            mediaPlacementCalculator: MediaPlacementCalculator(),
            mapSceneBuilder: MapSceneBuilder()
        )
    }

    func saveLocations(
        points: [(eastMeters: Double, seconds: TimeInterval)]
    ) async throws {
        for point in points {
            let timestamp = now.addingTimeInterval(point.seconds - 20000)
            _ = try await raw.saveLocationEvent(LocationEventData(
                latitude: 0,
                longitude: coordinate(eastMeters: point.eastMeters).longitude,
                timestamp: timestamp,
                horizontalAccuracy: 10,
                speedMetersPerSecond: nil,
                createdAt: timestamp,
                timeZoneIdentifier: "Asia/Tokyo",
                utcOffsetSeconds: 32400,
                localDateKey: day
            ))
        }
    }

    func saveVisit(
        eastMeters: Double,
        arrival: TimeInterval,
        departure: TimeInterval
    ) async throws {
        _ = try await raw.saveOrUpdateVisitEvent(VisitEventData(
            latitude: 0,
            longitude: coordinate(eastMeters: eastMeters).longitude,
            arrivalDate: now.addingTimeInterval(arrival - 20000),
            departureDate: now.addingTimeInterval(departure - 20000),
            horizontalAccuracy: 10,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: day
        ))
    }

    private func coordinate(eastMeters: Double) -> RouteCoordinate {
        RouteCoordinate(latitude: 0, longitude: eastMeters / 6_371_000 * 180 / .pi)
    }
}

private nonisolated struct OverrideIntegrationClock: Clock {
    let now: Date
}

private nonisolated struct OverrideIntegrationLogger: Logging {
    func debug(_: LogEvent) {}
    func info(_: LogEvent) {}
    func error(_: LogEvent) {}
}
