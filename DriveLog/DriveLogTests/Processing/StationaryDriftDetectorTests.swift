@testable import DriveLog
import Foundation
import Testing

@Suite("Stationary drift detector")
struct StationaryDriftDetectorTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let detector = StationaryDriftDetector(
        rules: ProcessingConfiguration.mvp.segmentation.stationaryDrift
    )

    @Test("accepts every stationary drift boundary value")
    func boundaryValues() {
        let candidate = candidate(duration: 300, distance: 150, maximumDisplacement: 60)
        let motions = [
            motion(start: 0, stationary: true),
            motion(start: 180, walking: true)
        ]

        #expect(detector.isStationaryDrift(candidate, motions: motions))
    }

    @Test("requires every duration speed progress and motion condition")
    func requiresEveryCondition() {
        let baselineMotions = [
            motion(start: 0, stationary: true),
            motion(start: 240, walking: true)
        ]
        let insufficientEvidence = [
            motion(start: 0, stationary: true),
            motion(start: 179)
        ]
        let travelDominant = [
            motion(start: 0, stationary: true),
            motion(start: 179, walking: true)
        ]

        #expect(!detector.isStationaryDrift(
            candidate(duration: 299, distance: 100, maximumDisplacement: 25),
            motions: baselineMotions
        ))
        #expect(!detector.isStationaryDrift(
            candidate(duration: 300, distance: 151, maximumDisplacement: 60),
            motions: baselineMotions
        ))
        #expect(!detector.isStationaryDrift(
            candidate(duration: 300, distance: 100, maximumDisplacement: 41),
            motions: baselineMotions
        ))
        #expect(!detector.isStationaryDrift(
            candidate(duration: 300, distance: 100, maximumDisplacement: 25),
            motions: insufficientEvidence
        ))
        #expect(!detector.isStationaryDrift(
            candidate(duration: 300, distance: 100, maximumDisplacement: 25),
            motions: travelDominant
        ))
    }

    @Test("replaces an open snapshot with the next snapshot")
    func openSnapshotReplacement() {
        let motions = [
            motion(start: 0, stationary: true),
            motion(start: 180, walking: true)
        ]

        #expect(detector.isStationaryDrift(
            candidate(duration: 300, distance: 100, maximumDisplacement: 25),
            motions: motions
        ))
    }

    @Test("prefers travel when a snapshot also reports stationary")
    func travelWinsConflict() {
        let motions = [motion(start: 0, walking: true, stationary: true)]

        #expect(!detector.isStationaryDrift(
            candidate(duration: 300, distance: 100, maximumDisplacement: 25),
            motions: motions
        ))
    }

    @Test("keeps a candidate when classified motion evidence is absent")
    func missingMotionEvidence() {
        #expect(!detector.isStationaryDrift(
            candidate(duration: 600, distance: 200, maximumDisplacement: 50),
            motions: []
        ))
    }

    private func candidate(
        duration: TimeInterval,
        distance: Double,
        maximumDisplacement: Double
    ) -> MovementSegmentCandidate {
        let locations = [
            location(distance: 0, seconds: 0),
            location(distance: maximumDisplacement, seconds: duration / 3),
            location(distance: 0, seconds: duration * 2 / 3),
            location(distance: maximumDisplacement / 2, seconds: duration)
        ]
        return MovementSegmentCandidate(
            localDateKey: "2023-11-15",
            startDate: locations[0].timestamp,
            endDate: locations[3].timestamp,
            locations: locations,
            distanceMeters: distance,
            estimatedAverageSpeedMetersPerSecond: distance / duration
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
            localDateKey: "2023-11-15"
        )
    }

    private func motion(
        start: TimeInterval,
        walking: Bool = false,
        stationary: Bool = false
    ) -> MotionEventData {
        MotionEventData(
            startDate: baseDate.addingTimeInterval(start),
            endDate: nil,
            isAutomotive: false,
            isWalking: walking,
            isRunning: false,
            isCycling: false,
            isStationary: stationary,
            isUnknown: !walking && !stationary,
            confidence: .high,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2023-11-15"
        )
    }
}
