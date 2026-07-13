@testable import DriveLog
import Foundation
import Testing

@Suite("Stay traffic and signal filtering")
struct StayTrafficFilteringTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("hides a straight automotive stationary automotive gap")
    func trafficCandidate() {
        #expect(detect().first?.isVisibleByAutomaticRule == false)
    }

    @Test("keeps candidates with walking or a visit")
    func strongerStayEvidence() {
        let walking = motion(start: 200, end: 300, walking: true)
        let visit = VisitEventData(
            latitude: 0,
            longitude: 0,
            arrivalDate: baseDate.addingTimeInterval(100),
            departureDate: baseDate.addingTimeInterval(500),
            horizontalAccuracy: 10,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )

        #expect(detect(extraMotions: [walking]).first?.isVisibleByAutomaticRule == true)
        #expect(detect(visits: [visit]).first?.isVisibleByAutomaticRule == true)
    }

    @Test("keeps candidates after a large turn or with missing direction evidence")
    func directionEvidence() {
        #expect(detect(followingBearingDegrees: 180).first?.isVisibleByAutomaticRule == true)
        #expect(detect(includeSegments: false).first?.isVisibleByAutomaticRule == true)
    }

    @Test("includes 45 degrees and excludes values above the tolerance")
    func directionBoundary() {
        #expect(detect(followingBearingDegrees: 45).first?.isVisibleByAutomaticRule == false)
        #expect(detect(followingBearingDegrees: 44.9).first?.isVisibleByAutomaticRule == true)
    }

    @Test("confirm override wins over traffic filtering")
    func confirmOverride() {
        let automatic = detect().first
        let stableID = automatic?.stableID ?? ""
        let override = StayOverrideData(
            overrideKey: stableID,
            targetStableID: stableID,
            localDateKey: "2024-01-01",
            originalArrivalDate: baseDate,
            originalDepartureDate: baseDate.addingTimeInterval(600),
            originalCoordinate: RouteCoordinate(latitude: 0, longitude: 0),
            action: .confirm,
            createdAt: baseDate,
            updatedAt: baseDate
        )

        #expect(detect(overrides: [override]).first?.isVisibleByAutomaticRule == true)
    }

    private func detect(
        followingBearingDegrees: Double = 90,
        includeSegments: Bool = true,
        extraMotions: [MotionEventData] = [],
        visits: [VisitEventData] = [],
        overrides: [StayOverrideData] = []
    ) -> [StaySegmentData] {
        let beforeStart = location(east: -200, north: 0, seconds: -60)
        let gapStart = location(east: 0, north: 0, seconds: 0)
        let gapEnd = location(east: 0, north: 0, seconds: 600)
        let radians = followingBearingDegrees * .pi / 180
        let afterEnd = location(
            east: sin(radians) * 200,
            north: cos(radians) * 200,
            seconds: 660
        )
        let gap = GapCandidate(
            precedingLocation: gapStart,
            followingLocation: gapEnd,
            reason: .continuousGap
        )
        let segments = includeSegments ? [
            candidate([beforeStart, gapStart]),
            candidate([gapEnd, afterEnd])
        ] : []
        let segmentation = MovementSegmentationResult(
            segments: segments,
            gaps: [gap],
            discardedSegments: []
        )
        return detector.detect(
            segmentation: segmentation,
            motions: trafficMotions + extraMotions,
            visits: visits,
            overrides: overrides
        )
    }

    private var detector: StayDetector {
        StayDetector(
            rules: ProcessingConfiguration.mvp.stay,
            stableIDGenerator: SHA256StableIDGenerator(),
            sourceRawRevision: 7,
            generatedAt: generatedAt
        )
    }

    private var trafficMotions: [MotionEventData] {
        [
            motion(start: -60, end: 0, automotive: true),
            motion(start: 0, end: 600, stationary: true),
            motion(start: 600, end: 660, automotive: true)
        ]
    }

    private func candidate(_ locations: [LocationEventData]) -> MovementSegmentCandidate {
        MovementSegmentCandidate(
            localDateKey: "2024-01-01",
            startDate: locations[0].timestamp,
            endDate: locations[1].timestamp,
            locations: locations,
            distanceMeters: 200
        )
    }

    private func location(
        east: Double,
        north: Double,
        seconds: TimeInterval
    ) -> LocationEventData {
        LocationEventData(
            latitude: north / 6_371_000 * 180 / .pi,
            longitude: east / 6_371_000 * 180 / .pi,
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
        start: TimeInterval,
        end: TimeInterval,
        automotive: Bool = false,
        walking: Bool = false,
        stationary: Bool = false
    ) -> MotionEventData {
        MotionEventData(
            startDate: baseDate.addingTimeInterval(start),
            endDate: baseDate.addingTimeInterval(end),
            isAutomotive: automotive,
            isWalking: walking,
            isRunning: false,
            isCycling: false,
            isStationary: stationary,
            isUnknown: false,
            confidence: .high,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}
