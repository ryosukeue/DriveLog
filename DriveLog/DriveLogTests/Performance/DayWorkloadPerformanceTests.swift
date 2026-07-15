@testable import DriveLog
import Foundation
import Testing

@Suite("Day workload performance")
struct DayWorkloadPerformanceTests {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("processes representative daily workload within five seconds")
    func representativeWorkload() async throws {
        let clock = ContinuousClock()
        let start = clock.now
        let locations = (0 ..< 1000).map(location)
        let result = try await DefaultDayProcessor(
            clock: PerformanceClock(now: date.addingTimeInterval(12000))
        ).process(
            localDateKey: "2024-01-01",
            rawEvents: RawDayEvents(
                locations: locations,
                motions: [],
                visits: [],
                classificationOverrides: [],
                stayOverrides: []
            ),
            mediaCount: 1000,
            rawRevision: 1
        )
        let scene = MapSceneBuilder().build(
            movements: (0 ..< 100).map(movement),
            stays: (0 ..< 100).map(stay),
            media: (0 ..< 1000).map(media)
        )

        #expect(result.aggregate.locationRecordCount == 1000)
        #expect(result.aggregate.mediaCountCache == 1000)
        #expect(scene.polylines.count == 100)
        #expect(scene.stayAnnotations.count == 100)
        #expect(scene.mediaAnnotations.count == 1000)
        #expect(start.duration(to: clock.now) < .seconds(5))
    }

    private func location(_ index: Int) -> LocationEventData {
        LocationEventData(
            latitude: 35.68,
            longitude: 139.76 + Double(index) * 0.000_3,
            timestamp: date.addingTimeInterval(Double(index) * 10),
            horizontalAccuracy: 10,
            speedMetersPerSecond: 10,
            createdAt: date,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }

    private func movement(_ index: Int) -> MovementSegmentData {
        let coordinate = coordinate(index)
        return MovementSegmentData(
            stableID: "movement-\(index)",
            localDateKey: "2024-01-01",
            startDate: date,
            endDate: date.addingTimeInterval(60),
            distanceMeters: 500,
            durationSeconds: 60,
            estimatedAverageSpeedMetersPerSecond: 8,
            automaticClassification: .automotiveLike,
            classificationConfidence: .high,
            route: [coordinate, self.coordinate(index + 1)],
            labelCoordinate: coordinate,
            sourceRawRevision: 1,
            generatedAt: date
        )
    }

    private func stay(_ index: Int) -> StaySegmentData {
        StaySegmentData(
            stableID: "stay-\(index)",
            localDateKey: "2024-01-01",
            representativeCoordinate: coordinate(index),
            estimatedArrivalDate: date,
            estimatedDepartureDate: date.addingTimeInterval(600),
            durationSeconds: 600,
            confidence: .high,
            source: .combined,
            isVisibleByAutomaticRule: true,
            sourceRawRevision: 1,
            generatedAt: date
        )
    }

    private func media(_ index: Int) -> MediaPlacement {
        MediaPlacement(
            assetIdentifier: "media-\(index)",
            mediaType: .photo,
            coordinate: coordinate(index),
            relatedMovementStableID: nil
        )
    }

    private func coordinate(_ index: Int) -> RouteCoordinate {
        RouteCoordinate(latitude: 35.68, longitude: 139.76 + Double(index) * 0.000_001)
    }
}

private struct PerformanceClock: Clock {
    let now: Date
}
