import Foundation

nonisolated protocol MovementClassifying: Sendable {
    func classify(
        segment: MovementSegmentCandidate,
        motions: [MotionEventData]
    ) -> MovementClassificationResult
}

nonisolated struct MovementClassificationResult: Sendable, Equatable {
    let automaticType: AutomaticMovementType
    let confidence: ClassificationConfidence
    let evidence: [ClassificationEvidence]
}

nonisolated enum ClassificationEvidence: Sendable, Equatable {
    case automotiveMotion(weightedRatio: Double)
    case walkingOrRunningMotion(weightedRatio: Double)
    case cyclingMotion(weightedRatio: Double)
    case unknownMotion(weightedRatio: Double)
    case speedDistanceFallback
    case insufficientData
    case conflictingMotion
}

nonisolated struct MovementClassifier: MovementClassifying {
    private let rules: ClassificationRules

    init(rules: ClassificationRules) {
        self.rules = rules
    }

    func classify(
        segment: MovementSegmentCandidate,
        motions: [MotionEventData]
    ) -> MovementClassificationResult {
        guard segment.locations.count >= 2, segment.durationSeconds > 0 else {
            return MovementClassificationResult(
                automaticType: .other,
                confidence: .low,
                evidence: [.insufficientData]
            )
        }

        let occupancy = weightedOccupancy(segment: segment, motions: motions)
        var evidence = occupancy.evidence
        let hasMotion = occupancy.maximumRatio > 0
        if isCyclingOrUnknownDominant(occupancy) {
            return result(type: .other, ratio: occupancy.maximumRatio, conflict: false, evidence: evidence)
        }

        let automotive = occupancy.automotive >= rules.automotiveMotionRatio
        let walking = occupancy.walkingOrRunning >= rules.walkingMotionRatio
        if automotive || walking {
            if automotive, walking {
                evidence.append(.conflictingMotion)
                let type: AutomaticMovementType = occupancy.automotive >= occupancy.walkingOrRunning ?
                    .automotiveLike : .walkingLike
                return result(
                    type: type,
                    ratio: max(occupancy.automotive, occupancy.walkingOrRunning),
                    conflict: true,
                    evidence: evidence
                )
            }
            let type: AutomaticMovementType = automotive ? .automotiveLike : .walkingLike
            let ratio = automotive ? occupancy.automotive : occupancy.walkingOrRunning
            return result(type: type, ratio: ratio, conflict: false, evidence: evidence)
        }

        guard !hasMotion else {
            return result(type: .other, ratio: occupancy.maximumRatio, conflict: true, evidence: evidence)
        }
        return fallbackResult(segment: segment, evidence: evidence)
    }

    private func fallbackResult(
        segment: MovementSegmentCandidate,
        evidence initialEvidence: [ClassificationEvidence]
    ) -> MovementClassificationResult {
        var evidence = initialEvidence
        guard let averageSpeed = segment.estimatedAverageSpeedMetersPerSecond else {
            evidence.append(.insufficientData)
            return MovementClassificationResult(
                automaticType: .other, confidence: .low, evidence: evidence
            )
        }
        let matchesAutomotive = averageSpeed >= rules.automotiveFallbackSpeed &&
            segment.distanceMeters >= rules.automotiveFallbackDistance
        if matchesAutomotive {
            evidence.append(.speedDistanceFallback)
            return MovementClassificationResult(
                automaticType: .automotiveLike, confidence: .low, evidence: evidence
            )
        }
        let matchesWalking = averageSpeed <= rules.walkingFallbackMaximumSpeed &&
            segment.distanceMeters <= rules.walkingFallbackMaximumDistance
        if matchesWalking {
            evidence.append(.speedDistanceFallback)
            return MovementClassificationResult(
                automaticType: .walkingLike, confidence: .low, evidence: evidence
            )
        }
        evidence.append(.insufficientData)
        return MovementClassificationResult(
            automaticType: .other, confidence: .low, evidence: evidence
        )
    }

    private func result(
        type: AutomaticMovementType,
        ratio: Double,
        conflict: Bool,
        evidence: [ClassificationEvidence]
    ) -> MovementClassificationResult {
        let confidence: ClassificationConfidence = if ratio >= rules.highConfidenceMinimumRatio, !conflict {
            .high
        } else if ratio >= rules.mediumConfidenceMinimumRatio {
            .medium
        } else {
            .low
        }
        return MovementClassificationResult(
            automaticType: type, confidence: confidence, evidence: evidence
        )
    }

    private func isCyclingOrUnknownDominant(_ occupancy: MotionOccupancy) -> Bool {
        let other = max(occupancy.cycling, occupancy.unknown)
        return other >= rules.automotiveMotionRatio &&
            other >= occupancy.automotive &&
            other >= occupancy.walkingOrRunning
    }

    private func weightedOccupancy(
        segment: MovementSegmentCandidate,
        motions: [MotionEventData]
    ) -> MotionOccupancy {
        let relevant = motionIntervals(for: segment, motions: motions)
        let boundaries = Set(
            [segment.startDate, segment.endDate] + relevant.flatMap {
                [max($0.startDate, segment.startDate), min($0.endDate, segment.endDate)]
            }
        ).sorted()
        var occupancy = MotionOccupancy()
        for (start, end) in zip(boundaries, boundaries.dropFirst()) where end > start {
            let active = relevant.filter {
                $0.startDate < end && $0.endDate > start
            }
            let duration = end.timeIntervalSince(start)
            occupancy.automotive += duration * maximumWeight(active.map(\.event).filter(\.isAutomotive))
            occupancy.walkingOrRunning += duration * maximumWeight(active.filter {
                $0.event.isWalking || $0.event.isRunning
            }.map(\.event))
            occupancy.cycling += duration * maximumWeight(active.map(\.event).filter(\.isCycling))
            occupancy.unknown += duration * maximumWeight(active.map(\.event).filter(\.isUnknown))
        }
        return occupancy.divided(by: segment.durationSeconds)
    }

    private func motionIntervals(
        for segment: MovementSegmentCandidate,
        motions: [MotionEventData]
    ) -> [MotionInterval] {
        let ordered = motions.sorted(by: motionOrdering)
        return ordered.enumerated().compactMap { index, motion in
            let nextStartDate = index + 1 < ordered.count ? ordered[index + 1].startDate : nil
            let endDate = motion.endDate ?? nextStartDate ?? segment.endDate
            let startDate = max(motion.startDate, segment.startDate)
            let clippedEndDate = min(endDate, segment.endDate)
            guard startDate < clippedEndDate,
                  motion.startDate < segment.endDate,
                  endDate > segment.startDate
            else {
                return nil
            }
            return MotionInterval(
                event: motion,
                startDate: startDate,
                endDate: clippedEndDate
            )
        }
    }

    private func motionOrdering(_ lhs: MotionEventData, _ rhs: MotionEventData) -> Bool {
        if lhs.startDate != rhs.startDate {
            return lhs.startDate < rhs.startDate
        }
        switch (lhs.endDate, rhs.endDate) {
        case let (lhsEnd?, rhsEnd?) where lhsEnd != rhsEnd:
            return lhsEnd < rhsEnd
        case (nil, nil), (_?, _?):
            break
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        }
        let lhsFlags = [
            lhs.isAutomotive, lhs.isWalking, lhs.isRunning,
            lhs.isCycling, lhs.isStationary, lhs.isUnknown
        ]
        let rhsFlags = [
            rhs.isAutomotive, rhs.isWalking, rhs.isRunning,
            rhs.isCycling, rhs.isStationary, rhs.isUnknown
        ]
        for (lhsFlag, rhsFlag) in zip(lhsFlags, rhsFlags) where lhsFlag != rhsFlag {
            return !lhsFlag && rhsFlag
        }
        if lhs.confidence != rhs.confidence {
            return confidenceRank(lhs.confidence) < confidenceRank(rhs.confidence)
        }
        if lhs.timeZoneIdentifier != rhs.timeZoneIdentifier {
            return lhs.timeZoneIdentifier < rhs.timeZoneIdentifier
        }
        return lhs.utcOffsetSeconds < rhs.utcOffsetSeconds
    }

    private func confidenceRank(_ confidence: MotionConfidence) -> Int {
        switch confidence {
        case .low:
            0
        case .medium:
            1
        case .high:
            2
        }
    }

    private func maximumWeight(_ motions: [MotionEventData]) -> Double {
        motions.map { weight($0.confidence) }.max() ?? 0
    }

    private func weight(_ confidence: MotionConfidence) -> Double {
        switch confidence {
        case .low:
            rules.lowConfidenceWeight
        case .medium:
            rules.mediumConfidenceWeight
        case .high:
            rules.highConfidenceWeight
        }
    }
}

private nonisolated struct MotionInterval {
    let event: MotionEventData
    let startDate: Date
    let endDate: Date
}

private nonisolated struct MotionOccupancy {
    var automotive = 0.0
    var walkingOrRunning = 0.0
    var cycling = 0.0
    var unknown = 0.0

    var maximumRatio: Double {
        max(automotive, walkingOrRunning, cycling, unknown)
    }

    var evidence: [ClassificationEvidence] {
        var result: [ClassificationEvidence] = []
        if automotive > 0 {
            result.append(.automotiveMotion(weightedRatio: automotive))
        }
        if walkingOrRunning > 0 {
            result.append(.walkingOrRunningMotion(weightedRatio: walkingOrRunning))
        }
        if cycling > 0 {
            result.append(.cyclingMotion(weightedRatio: cycling))
        }
        if unknown > 0 {
            result.append(.unknownMotion(weightedRatio: unknown))
        }
        return result
    }

    func divided(by duration: TimeInterval) -> MotionOccupancy {
        MotionOccupancy(
            automotive: automotive / duration,
            walkingOrRunning: walkingOrRunning / duration,
            cycling: cycling / duration,
            unknown: unknown / duration
        )
    }
}
