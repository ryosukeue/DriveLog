@testable import DriveLog
import Foundation
import Testing

@Suite("Stay detector")
struct StayDetectorTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("applies three and five minute visibility boundaries")
    func durationBoundaries() {
        #expect(stay(duration: 179)?.isVisibleByAutomaticRule == false)
        #expect(stay(duration: 180)?.isVisibleByAutomaticRule == false)
        #expect(stay(duration: 299)?.isVisibleByAutomaticRule == false)
        #expect(stay(duration: 300)?.isVisibleByAutomaticRule == true)
        #expect(stay(duration: 301)?.isVisibleByAutomaticRule == true)
    }

    @Test("uses visit evidence between three and five minutes")
    func visitEvidence() {
        let gap = makeGap(duration: 180)
        let visit = makeVisit(arrival: 0, departure: 180, latitude: 36, longitude: 140)

        let result = detect(gaps: [gap], visits: [visit])

        #expect(result.first?.isVisibleByAutomaticRule == true)
        #expect(result.first?.source == .visit)
        #expect(result.first?.confidence == .high)
    }

    @Test("uses automotive to walking with optional stationary evidence")
    func motionEvidence() {
        let gap = makeGap(duration: 240)
        let direct = [
            makeMotion(start: 0, end: 120, automotive: true),
            makeMotion(start: 120, end: 240, walking: true)
        ]
        let viaStationary = [
            makeMotion(start: 0, end: 80, automotive: true),
            makeMotion(start: 80, end: 160, stationary: true),
            makeMotion(start: 160, end: 240, walking: true)
        ]

        let directStay = detect(gaps: [gap], motions: direct).first
        let stationaryStay = detect(gaps: [gap], motions: viaStationary).first

        #expect(directStay?.isVisibleByAutomaticRule == true)
        #expect(directStay?.source == .motionTransition)
        #expect(directStay?.confidence == .medium)
        #expect(stationaryStay?.isVisibleByAutomaticRule == true)
    }

    @Test("accepts the 150 meter radius and rejects values above it")
    func stayRadius() {
        let boundary = makeGap(duration: 300, distance: 150)
        let outside = makeGap(duration: 300, distance: 150.01)

        #expect(detect(gaps: [boundary]).count == 1)
        #expect(detect(gaps: [outside]).isEmpty)
    }

    @Test("prioritizes visit coordinate and dates")
    func visitValues() {
        let gap = makeGap(duration: 600, distance: 1000)
        let visit = makeVisit(
            arrival: 60,
            departure: 540,
            latitude: 36.5,
            longitude: 140.5
        )

        let result = detect(gaps: [gap], visits: [visit]).first

        #expect(result?.representativeCoordinate == RouteCoordinate(latitude: 36.5, longitude: 140.5))
        #expect(result?.estimatedArrivalDate == baseDate.addingTimeInterval(60))
        #expect(result?.estimatedDepartureDate == baseDate.addingTimeInterval(540))
        #expect(result?.durationSeconds == 480)
    }

    @Test("uses the following location for an open visit departure")
    func openVisit() {
        let gap = makeGap(duration: 600)
        let visit = VisitEventData(
            latitude: 35,
            longitude: 139,
            arrivalDate: baseDate.addingTimeInterval(60),
            departureDate: nil,
            horizontalAccuracy: 10,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )

        let result = detect(gaps: [gap], visits: [visit]).first

        #expect(result?.estimatedArrivalDate == baseDate.addingTimeInterval(60))
        #expect(result?.estimatedDepartureDate == baseDate.addingTimeInterval(600))
    }

    @Test("prefers a completed visit over its arrival-only duplicate")
    func completedVisitPreferred() {
        let gap = makeGap(duration: 600)
        let open = VisitEventData(
            latitude: 35,
            longitude: 139,
            arrivalDate: baseDate.addingTimeInterval(60),
            departureDate: nil,
            horizontalAccuracy: 10,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
        let completed = makeVisit(
            arrival: 60,
            departure: 540,
            latitude: 36,
            longitude: 140
        )

        let result = detect(gaps: [gap], visits: [open, completed]).first

        #expect(result?.estimatedDepartureDate == baseDate.addingTimeInterval(540))
        #expect(result?.durationSeconds == 480)
        #expect(result?.representativeCoordinate == RouteCoordinate(latitude: 36, longitude: 140))
    }

    @Test("applies exact stable ID overrides")
    func overrides() {
        let gap = makeGap(duration: 240)
        let automatic = detect(gaps: [gap]).first
        let stableID = automatic?.stableID ?? ""

        #expect(detect(gaps: [gap], overrides: [makeOverride(stableID: stableID, action: .confirm)])
            .first?.isVisibleByAutomaticRule == true)
        #expect(detect(
            gaps: [makeGap(duration: 300)],
            overrides: [makeOverride(
                stableID: detect(gaps: [makeGap(duration: 300)]).first?.stableID ?? "",
                action: .hide
            )]
        ).first?.isVisibleByAutomaticRule == false)
        #expect(detect(gaps: [gap], overrides: [makeOverride(stableID: stableID, action: .automatic)])
            .first?.isVisibleByAutomaticRule == false)
    }

    @Test("does not create a cross-day stay and preserves generation metadata")
    func dayBoundaryAndMetadata() {
        let dayBoundary = makeGap(duration: 600, reason: .localDayBoundary)
        let normal = makeGap(duration: 600)

        #expect(detect(gaps: [dayBoundary]).isEmpty)
        let result = detect(gaps: [normal, makeGap(duration: 700, offset: 1000)])
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.sourceRawRevision == 7 && $0.generatedAt == generatedAt })
        #expect(result[0].stableID != result[1].stableID)
    }
}

extension StayDetectorTests {
    private func stay(duration: TimeInterval) -> StaySegmentData? {
        detect(gaps: [makeGap(duration: duration)]).first
    }

    private func detect(
        gaps: [GapCandidate],
        motions: [MotionEventData] = [],
        visits: [VisitEventData] = [],
        overrides: [StayOverrideData] = []
    ) -> [StaySegmentData] {
        detector.detect(
            segmentation: MovementSegmentationResult(
                segments: [], gaps: gaps, discardedSegments: []
            ),
            motions: motions,
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

    private func makeGap(
        duration: TimeInterval,
        distance: Double = 0,
        offset: TimeInterval = 0,
        reason: SegmentationBoundaryReason = .continuousGap
    ) -> GapCandidate {
        GapCandidate(
            precedingLocation: makeLocation(distance: 0, seconds: offset),
            followingLocation: makeLocation(distance: distance, seconds: offset + duration),
            reason: reason
        )
    }

    private func makeLocation(distance: Double, seconds: TimeInterval) -> LocationEventData {
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

    private func makeVisit(
        arrival: TimeInterval,
        departure: TimeInterval,
        latitude: Double,
        longitude: Double
    ) -> VisitEventData {
        VisitEventData(
            latitude: latitude,
            longitude: longitude,
            arrivalDate: baseDate.addingTimeInterval(arrival),
            departureDate: baseDate.addingTimeInterval(departure),
            horizontalAccuracy: 10,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }

    private func makeMotion(
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

    private func makeOverride(stableID: String, action: StayOverrideAction) -> StayOverrideData {
        StayOverrideData(
            overrideKey: stableID,
            targetStableID: stableID,
            localDateKey: "2024-01-01",
            originalArrivalDate: baseDate,
            originalDepartureDate: baseDate.addingTimeInterval(300),
            originalCoordinate: RouteCoordinate(latitude: 0, longitude: 0),
            action: action,
            createdAt: baseDate,
            updatedAt: baseDate
        )
    }
}
