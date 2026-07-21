@testable import DriveLog
import Foundation
import Testing

@Suite("Movement classifier")
struct MovementClassifierTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let classifier = MovementClassifier(rules: ProcessingConfiguration.mvp.classification)

    @Test(arguments: [0.49, 0.50, 0.51])
    func automotiveRatioBoundary(ratio: Double) {
        let result = classify(motions: [motion(endRatio: ratio, automotive: true)])

        #expect(result.automaticType == (ratio >= 0.5 ? .automotiveLike : .other))
    }

    @Test(arguments: [0.39, 0.40, 0.41])
    func walkingRatioBoundary(ratio: Double) {
        let result = classify(motions: [motion(endRatio: ratio, walking: true)])

        #expect(result.automaticType == (ratio >= 0.4 ? .walkingLike : .other))
    }

    @Test("weights confidence and assigns high medium and low confidence")
    func confidenceWeights() {
        let high = classify(motions: [motion(endRatio: 0.7, automotive: true)])
        let medium = classify(motions: [
            motion(endRatio: 0.6, automotive: true, confidence: .medium)
        ])
        let low = classify(segment: segment(distance: 500, duration: 120), motions: [])

        #expect(high.confidence == .high)
        #expect(medium.automaticType == .other)
        #expect(medium.confidence == .medium)
        #expect(low.automaticType == .automotiveLike)
        #expect(low.confidence == .low)
    }

    @Test("does not double count overlapping events of the same state")
    func overlappingMotion() {
        let result = classify(motions: [
            motion(endRatio: 1, automotive: true),
            motion(endRatio: 1, automotive: true, confidence: .low)
        ])

        #expect(result.evidence == [.automotiveMotion(weightedRatio: 1)])
        #expect(result.confidence == .high)
    }

    @Test("limits an open snapshot to the next snapshot")
    func openSnapshotUsesNextSnapshotBoundary() {
        let segment = segment(distance: 1000, duration: 100)
        let automotive = openMotion(startOffset: 0, automotive: true)
        let walking = openMotion(startOffset: 40, walking: true)

        let result = classify(segment: segment, motions: [walking, automotive])

        #expect(result.automaticType == .walkingLike)
    }

    @Test("uses the movement end for the last open snapshot")
    func lastOpenSnapshotUsesMovementBoundary() {
        let segment = segment(distance: 1000, duration: 100)
        let automotive = openMotion(startOffset: 60, automotive: true)

        let result = classify(segment: segment, motions: [automotive])

        #expect(result.automaticType == .other)
        #expect(result.evidence == [.automotiveMotion(weightedRatio: 0.4)])
    }

    @Test("open snapshot classification is independent of input order")
    func openSnapshotOrderingIsDeterministic() {
        let segment = segment(distance: 1000, duration: 100)
        let automotive = openMotion(startOffset: 0, automotive: true)
        let walking = openMotion(startOffset: 40, walking: true)

        let forward = classify(segment: segment, motions: [automotive, walking])
        let reversed = classify(segment: segment, motions: [walking, automotive])

        #expect(forward == reversed)
    }

    @Test("resolves conflicting motion by ratio and automotive tie break")
    func conflictingMotion() {
        let automotiveTie = motion(endRatio: 0.6, automotive: true, walking: true)
        let walkingWinner = [
            motion(endRatio: 0.5, automotive: true),
            motion(endRatio: 0.7, walking: true)
        ]

        let tieResult = classify(motions: [automotiveTie])
        let walkingResult = classify(motions: walkingWinner)

        #expect(tieResult.automaticType == .automotiveLike)
        #expect(tieResult.confidence == .medium)
        #expect(tieResult.evidence.last == .conflictingMotion)
        #expect(walkingResult.automaticType == .walkingLike)
    }

    @Test("uses automotive fallback only at both speed and distance boundaries")
    func automotiveFallback() {
        let speed = 15 / 3.6
        let boundary = classify(segment: segment(distance: 500, duration: 120))
        let shortDistance = classify(segment: segment(distance: 499, duration: 499 / speed))
        let slow = classify(segment: segment(distance: 500, duration: 500 / (speed - 0.01)))

        #expect(boundary.automaticType == .automotiveLike)
        #expect(boundary.evidence == [.speedDistanceFallback])
        #expect(shortDistance.automaticType == .other)
        #expect(slow.automaticType == .other)
    }

    @Test("uses walking fallback only at both speed and distance boundaries")
    func walkingFallback() {
        let speed = 8 / 3.6
        let boundary = classify(segment: segment(distance: 3000, duration: 3000 / speed))
        let fast = classify(segment: segment(distance: 3000, duration: 3000 / (speed + 0.01)))
        let long = classify(segment: segment(distance: 3001, duration: 3001 / speed))

        #expect(boundary.automaticType == .walkingLike)
        #expect(fast.automaticType == .other)
        #expect(long.automaticType == .other)
    }

    @Test("classifies dominant cycling and unknown as other")
    func otherMotion() {
        let cycling = classify(motions: [motion(endRatio: 0.8, cycling: true)])
        let unknown = classify(motions: [motion(endRatio: 0.8, unknown: true)])

        #expect(cycling.automaticType == .other)
        #expect(cycling.confidence == .high)
        #expect(unknown.automaticType == .other)
        #expect(unknown.evidence == [.unknownMotion(weightedRatio: 0.8)])
    }

    @Test("returns other low for insufficient points or non-positive duration")
    func insufficientData() {
        let onePoint = MovementSegmentCandidate(
            localDateKey: "2024-01-01",
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(60),
            locations: [location(seconds: 0)],
            distanceMeters: 100
        )
        let zeroDuration = segment(distance: 100, duration: 0)

        #expect(classify(segment: onePoint).evidence == [.insufficientData])
        #expect(classify(segment: zeroDuration).automaticType == .other)
        #expect(classify(segment: zeroDuration).confidence == .low)
    }
}

extension MovementClassifierTests {
    private func classify(
        segment: MovementSegmentCandidate? = nil,
        motions: [MotionEventData] = []
    ) -> MovementClassificationResult {
        classifier.classify(
            segment: segment ?? self.segment(distance: 1000, duration: 1000),
            motions: motions
        )
    }

    private func segment(distance: Double, duration: TimeInterval) -> MovementSegmentCandidate {
        let averageSpeed = duration >= 120 && distance >= 100 && duration > 0 ? distance / duration : nil
        return MovementSegmentCandidate(
            localDateKey: "2024-01-01",
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(duration),
            locations: [location(seconds: 0), location(seconds: duration)],
            distanceMeters: distance,
            estimatedAverageSpeedMetersPerSecond: averageSpeed
        )
    }

    private func location(seconds: TimeInterval) -> LocationEventData {
        LocationEventData(
            latitude: 35,
            longitude: 139,
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
        endRatio: Double,
        automotive: Bool = false,
        walking: Bool = false,
        cycling: Bool = false,
        unknown: Bool = false,
        confidence: MotionConfidence = .high
    ) -> MotionEventData {
        MotionEventData(
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(1000 * endRatio),
            isAutomotive: automotive,
            isWalking: walking,
            isRunning: false,
            isCycling: cycling,
            isStationary: false,
            isUnknown: unknown,
            confidence: confidence,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }

    private func openMotion(
        startOffset: TimeInterval,
        automotive: Bool = false,
        walking: Bool = false,
        cycling: Bool = false,
        unknown: Bool = false,
        confidence: MotionConfidence = .high
    ) -> MotionEventData {
        MotionEventData(
            startDate: baseDate.addingTimeInterval(startOffset), endDate: nil,
            isAutomotive: automotive, isWalking: walking,
            isRunning: false, isCycling: cycling, isStationary: false,
            isUnknown: unknown, confidence: confidence,
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}
