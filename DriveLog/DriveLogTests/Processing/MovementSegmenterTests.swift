@testable import DriveLog
import Foundation
import Testing

@Suite("Movement segmenter")
struct MovementSegmenterTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let segmenter = MovementSegmenter(
        segmentationRules: ProcessingConfiguration.mvp.segmentation,
        stayRules: ProcessingConfiguration.mvp.stay
    )

    @Test("handles empty and single-point inputs")
    func emptyAndSinglePoint() {
        let empty = segmenter.segment(
            locations: SanitizedLocations(accepted: [], rejected: []), motions: [], visits: []
        )
        let point = location(distance: 0, seconds: 0)
        let single = segment([point])

        #expect(empty == MovementSegmentationResult(segments: [], gaps: [], discardedSegments: []))
        #expect(single.segments.isEmpty)
        #expect(single.discardedSegments.map(\.locations) == [[point]])
    }

    @Test("keeps continuous movement below 15 minutes")
    func continuousMovement() {
        let first = location(distance: 0, seconds: 0)
        let second = location(distance: 200, seconds: 899)

        let result = segment([first, second])

        #expect(result.segments.count == 1)
        #expect(result.gaps.isEmpty)
        #expect(abs(result.segments[0].distanceMeters - 200) < 0.001)
    }

    @Test(arguments: [900.0, 901.0])
    func doesNotBridgeStationaryEndpointsAtFifteenMinutes(gap: TimeInterval) {
        let points = boundaryPoints(gap: gap)

        let result = segment(points)

        #expect(result.segments.map(\.locations) == [
            Array(points[0 ... 1]), Array(points[2 ... 3])
        ])
        #expect(result.gaps.map(\.reason) == [.stationaryStay])
    }

    @Test("connects a plausible route across a gap longer than fifteen minutes")
    func connectsPlausibleLongGap() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 2200, seconds: 16 * 60),
            location(distance: 2400, seconds: 17 * 60)
        ]

        let result = segment(points)

        #expect(result.segments.map(\.locations) == [points])
        #expect(result.gaps.isEmpty)
    }

    @Test("connects a long sparse route when travel motion overlaps the gap")
    func connectsLongGapUsingMotionEvidence() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 2200, seconds: 60 + 45 * 60),
            location(distance: 2400, seconds: 120 + 45 * 60)
        ]
        let motions = [motion(start: 30, end: 45 * 60 + 90, automotive: true)]

        let result = segment(points, motions: motions)

        #expect(result.segments.map(\.locations) == [points])
        #expect(result.gaps.isEmpty)
    }

    @Test("splits a soft gap when distance speed and motion provide no continuity evidence")
    func splitsSoftGapWithoutContinuityEvidence() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 400, seconds: 60 + 45 * 60),
            location(distance: 600, seconds: 120 + 45 * 60)
        ]

        let result = segment(points)

        #expect(result.segments.map(\.locations) == [
            Array(points[0 ... 1]), Array(points[2 ... 3])
        ])
        #expect(result.gaps.map(\.reason) == [.continuousGap])
    }

    @Test("splits at the absolute ninety minute gap")
    func splitsAtAbsoluteGap() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 30_200, seconds: 60 + 90 * 60),
            location(distance: 30_400, seconds: 120 + 90 * 60)
        ]

        let result = segment(
            points,
            motions: [motion(start: 30, end: 90 * 60 + 90, automotive: true)]
        )

        #expect(result.segments.map(\.locations) == [
            Array(points[0 ... 1]), Array(points[2 ... 3])
        ])
        #expect(result.gaps.map(\.reason) == [.continuousGap])
    }

    @Test("does not bridge an implausible location jump")
    func rejectsImplausibleLongGapBridge() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 100_200, seconds: 20 * 60),
            location(distance: 100_400, seconds: 21 * 60)
        ]

        let result = segment(points)

        #expect(result.segments.map(\.locations) == [
            Array(points[0 ... 1]), Array(points[2 ... 3])
        ])
        #expect(result.gaps.map(\.reason) == [.continuousGap])
    }

    @Test("splits at the recorded local date boundary")
    func localDayBoundary() {
        let points = [
            location(distance: 0, seconds: 0, key: "2024-01-01"),
            location(distance: 200, seconds: 60, key: "2024-01-01"),
            location(distance: 300, seconds: 120, key: "2024-01-02"),
            location(distance: 500, seconds: 180, key: "2024-01-02")
        ]

        let result = segment(points)

        #expect(result.segments.map(\.localDateKey) == ["2024-01-01", "2024-01-02"])
        #expect(result.gaps.map(\.reason) == [.localDayBoundary])
    }

    @Test("keeps the route continuous across visits")
    func visitBoundary() {
        let points = boundaryPoints(gap: 120)
        let visits = [
            visit(arrival: 70, departure: 100),
            visit(arrival: 80, departure: 110)
        ]

        let result = segment(points, visits: visits)

        #expect(result.segments.count == 1)
        #expect(result.gaps.map(\.reason) == [.visit])
    }

    @Test("keeps the route continuous across motion transitions")
    func motionTransitions() {
        let splitPoints = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 300, seconds: 300),
            location(distance: 500, seconds: 360)
        ]
        let motions = travelTransition(from: 50, transition: 180, to: 310, automotiveFirst: true)
        let reverseMotions = travelTransition(
            from: 50, transition: 180, to: 310, automotiveFirst: false
        )
        let shortPoints = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 400, seconds: 150)
        ]

        #expect(segment(splitPoints, motions: motions).gaps.map(\.reason) == [.motionTransition])
        #expect(segment(splitPoints, motions: reverseMotions).gaps.map(\.reason) == [
            .motionTransition
        ])
        #expect(segment(shortPoints, motions: motions).gaps.isEmpty)
    }

    @Test("does not split cycling running or unknown changes")
    func unsupportedMotionChanges() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 400, seconds: 300)
        ]
        let motions = [
            motion(start: 50, end: 180, cycling: true),
            motion(start: 180, end: 310, running: true)
        ]

        let result = segment(points, motions: motions)

        #expect(result.gaps.isEmpty)
        #expect(result.segments.count == 1)
    }

    @Test("requires two points and at least 100 meters")
    func minimumSegmentRules() {
        let boundary = segment([
            location(distance: 0, seconds: 0), location(distance: 100, seconds: 60)
        ])
        let tooShort = segment([
            location(distance: 0, seconds: 0), location(distance: 99.9, seconds: 60)
        ])

        #expect(boundary.segments.count == 1)
        #expect(tooShort.segments.isEmpty)
        #expect(tooShort.discardedSegments.count == 1)
    }

    @Test("does not create short chunks at motion boundaries")
    func noShortMotionChunk() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 250, seconds: 300),
            location(distance: 500, seconds: 540),
            location(distance: 700, seconds: 600)
        ]
        let motions = travelTransition(from: 50, transition: 180, to: 310, automotiveFirst: true) +
            travelTransition(from: 290, transition: 420, to: 550, automotiveFirst: false)

        let result = segment(points, motions: motions)

        #expect(result.segments.map(\.locations) == [points])
        #expect(result.discardedSegments.isEmpty)
        #expect(result.gaps.count == 2)
    }

    @Test("does not merge a short chunk across absolute gaps")
    func doesNotMergeAcrossHardGap() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 250, seconds: 5460),
            location(distance: 500, seconds: 10_860),
            location(distance: 700, seconds: 10_920)
        ]

        let result = segment(points)

        #expect(result.segments.map(\.locations) == [
            Array(points[0 ... 1]), Array(points[3 ... 4])
        ])
        #expect(result.discardedSegments.map(\.locations) == [[points[2]]])
        #expect(result.gaps.map(\.reason) == [.continuousGap, .continuousGap])
    }

    private func segment(
        _ locations: [LocationEventData],
        motions: [MotionEventData] = [],
        visits: [VisitEventData] = []
    ) -> MovementSegmentationResult {
        segmenter.segment(
            locations: SanitizedLocations(accepted: locations, rejected: []),
            motions: motions,
            visits: visits
        )
    }

    private func boundaryPoints(gap: TimeInterval) -> [LocationEventData] {
        [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 300, seconds: 60 + gap),
            location(distance: 500, seconds: 120 + gap)
        ]
    }

    private func location(
        distance: Double,
        seconds: TimeInterval,
        key: String = "2024-01-01"
    ) -> LocationEventData {
        LocationEventData(
            latitude: 0,
            longitude: distance / 6_371_000 * 180 / .pi,
            timestamp: baseDate.addingTimeInterval(seconds),
            horizontalAccuracy: 10,
            speedMetersPerSecond: nil,
            createdAt: baseDate.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: key
        )
    }

    private func visit(arrival: TimeInterval, departure: TimeInterval) -> VisitEventData {
        VisitEventData(
            latitude: 0,
            longitude: 0,
            arrivalDate: baseDate.addingTimeInterval(arrival),
            departureDate: baseDate.addingTimeInterval(departure),
            horizontalAccuracy: 10,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }

    private func travelTransition(
        from start: TimeInterval,
        transition: TimeInterval,
        to end: TimeInterval,
        automotiveFirst: Bool
    ) -> [MotionEventData] {
        [
            motion(start: start, end: transition, automotive: automotiveFirst, walking: !automotiveFirst),
            motion(start: transition, end: end, automotive: !automotiveFirst, walking: automotiveFirst)
        ]
    }

    private func motion(
        start: TimeInterval,
        end: TimeInterval,
        automotive: Bool = false,
        walking: Bool = false,
        running: Bool = false,
        cycling: Bool = false
    ) -> MotionEventData {
        MotionEventData(
            startDate: baseDate.addingTimeInterval(start),
            endDate: baseDate.addingTimeInterval(end),
            isAutomotive: automotive,
            isWalking: walking,
            isRunning: running,
            isCycling: cycling,
            isStationary: false,
            isUnknown: !automotive && !walking && !running && !cycling,
            confidence: .high,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}

extension MovementSegmenterTests {
    @Test("keeps the arrival endpoint and excludes locations inside a confirmed stay")
    func confirmedVisitPartitionsMovement() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 3000, seconds: 600),
            location(distance: 3010, seconds: 900),
            location(distance: 3020, seconds: 1800),
            location(distance: 6000, seconds: 2400)
        ]

        let result = segment(points, visits: [visit(arrival: 590, departure: 1700)])

        #expect(result.segments.map(\.locations) == [
            Array(points[0 ... 1]), Array(points[3 ... 4])
        ])
        #expect(result.gaps.map(\.reason) == [.stationaryStay])
        #expect(result.discardedSegments.isEmpty)
    }

    @Test("does not partition locations for a visit shorter than five minutes")
    func shortVisitRemainsContinuous() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 210, seconds: 180),
            location(distance: 400, seconds: 300)
        ]

        let result = segment(points, visits: [visit(arrival: 50, departure: 290)])

        #expect(result.segments.map(\.locations) == [points])
        #expect(result.gaps.map(\.reason) == [.visit, .visit, .visit])
    }

    @Test("splits movement around a five minute stationary stay")
    func fiveMinuteStationaryStay() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 210, seconds: 360),
            location(distance: 410, seconds: 420)
        ]

        let result = segment(points)

        #expect(result.segments.map(\.locations) == [
            Array(points[0 ... 1]), Array(points[2 ... 3])
        ])
        #expect(result.gaps.map(\.reason) == [.stationaryStay])
    }

    @Test("does not infer a stationary stay below five minutes")
    func belowFiveMinuteStay() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 210, seconds: 359),
            location(distance: 410, seconds: 419)
        ]

        let result = segment(points)

        #expect(result.segments.map(\.locations) == [points])
        #expect(result.gaps.isEmpty)
    }

    @Test("does not infer a stay from a distant five minute location gap")
    func distantFiveMinuteGap() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 400, seconds: 360),
            location(distance: 600, seconds: 420)
        ]

        let result = segment(points)

        #expect(result.segments.map(\.locations) == [points])
        #expect(result.gaps.isEmpty)
    }

    @Test("a five minute visit splits even when endpoints are distant")
    func fiveMinuteVisit() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 400, seconds: 420),
            location(distance: 600, seconds: 480)
        ]

        let result = segment(points, visits: [visit(arrival: 90, departure: 390)])

        #expect(result.segments.map(\.locations) == [
            Array(points[0 ... 1]), Array(points[2 ... 3])
        ])
        #expect(result.gaps.map(\.reason) == [.stationaryStay])
    }

    @Test("arrival-only visits do not discard movement around sparse observations")
    func arrivalOnlyVisitsRemainContinuous() {
        let points = [
            location(distance: 0, seconds: 0),
            location(distance: 200, seconds: 60),
            location(distance: 12000, seconds: 1600),
            location(distance: 12400, seconds: 1950),
            location(distance: 12600, seconds: 2010)
        ]
        let visits = [openVisit(arrival: 1500), openVisit(arrival: 1900)]

        let result = segment(points, visits: visits)

        #expect(result.segments.map(\.locations) == [points])
        #expect(result.discardedSegments.isEmpty)
        #expect(result.gaps.map(\.reason) == [.visit, .visit])
    }

    private func openVisit(arrival: TimeInterval) -> VisitEventData {
        VisitEventData(
            latitude: 0,
            longitude: 0,
            arrivalDate: baseDate.addingTimeInterval(arrival),
            departureDate: nil,
            horizontalAccuracy: 10,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}
