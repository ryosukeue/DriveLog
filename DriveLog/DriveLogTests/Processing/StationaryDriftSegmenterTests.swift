@testable import DriveLog
import Foundation
import Testing

@Suite("Stationary drift segment integration")
struct StationaryDriftSegmenterTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let segmenter = MovementSegmenter(
        segmentationRules: ProcessingConfiguration.mvp.segmentation,
        stayRules: ProcessingConfiguration.mvp.stay
    )

    @Test("discards a slow stationary loop as GPS drift")
    func stationaryGPSDrift() {
        let points = loopPoints
        let motions = [motion(end: 300, stationary: true)]

        let result = segment(points, motions: motions)

        #expect(result.segments.isEmpty)
        #expect(result.discardedSegments.map(\.locations) == [points])
        #expect(result.stationaryDriftDiscardedCount == 1)
    }

    @Test("keeps a slow loop when walking evidence dominates")
    func slowWalkingLoop() {
        let points = loopPoints
        let motions = [motion(end: 300, walking: true)]

        let result = segment(points, motions: motions)

        #expect(result.segments.map(\.locations) == [points])
        #expect(result.stationaryDriftDiscardedCount == 0)
    }

    @Test("keeps a slow route that makes forward progress")
    func slowForwardProgress() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 60, seconds: 149),
            location(distance: 120, seconds: 298)
        ]
        let motions = [motion(end: 298, stationary: true)]

        let result = segment(points, motions: motions)

        #expect(result.segments.map(\.locations) == [points])
        #expect(result.stationaryDriftDiscardedCount == 0)
    }

    private var loopPoints: [LocationEventData] {
        [
            location(distance: 0, seconds: 0),
            location(distance: 60, seconds: 100),
            location(distance: 0, seconds: 200),
            location(distance: 30, seconds: 300)
        ]
    }

    private func segment(
        _ locations: [LocationEventData],
        motions: [MotionEventData]
    ) -> MovementSegmentationResult {
        segmenter.segment(
            locations: SanitizedLocations(accepted: locations, rejected: []),
            motions: motions,
            visits: []
        )
    }

    private func location(distance: Double, seconds: TimeInterval) -> LocationEventData {
        LocationEventData(
            latitude: 0,
            longitude: distance / 6_371_000 * 180 / .pi,
            timestamp: baseDate.addingTimeInterval(seconds),
            horizontalAccuracy: 10,
            speedMetersPerSecond: nil,
            createdAt: baseDate.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }

    private func motion(
        end: TimeInterval,
        walking: Bool = false,
        stationary: Bool = false
    ) -> MotionEventData {
        MotionEventData(
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(end),
            isAutomotive: false,
            isWalking: walking,
            isRunning: false,
            isCycling: false,
            isStationary: stationary,
            isUnknown: !walking && !stationary,
            confidence: .high,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}
