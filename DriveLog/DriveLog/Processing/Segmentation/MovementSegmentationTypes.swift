import Foundation

nonisolated protocol MovementSegmenting: Sendable {
    func segment(
        locations: SanitizedLocations,
        motions: [MotionEventData],
        visits: [VisitEventData]
    ) -> MovementSegmentationResult
}

nonisolated struct MovementSegmentationResult: Sendable, Equatable {
    let segments: [MovementSegmentCandidate]
    let gaps: [GapCandidate]
    let discardedSegments: [MovementSegmentCandidate]
    let stationaryDriftDiscardedCount: Int

    init(
        segments: [MovementSegmentCandidate],
        gaps: [GapCandidate],
        discardedSegments: [MovementSegmentCandidate],
        stationaryDriftDiscardedCount: Int = 0
    ) {
        self.segments = segments
        self.gaps = gaps
        self.discardedSegments = discardedSegments
        self.stationaryDriftDiscardedCount = stationaryDriftDiscardedCount
    }
}

nonisolated struct MovementSegmentCandidate: Sendable, Equatable {
    let localDateKey: String
    let startDate: Date
    let endDate: Date
    let locations: [LocationEventData]
    let distanceMeters: Double
    let estimatedAverageSpeedMetersPerSecond: Double?

    init(
        localDateKey: String,
        startDate: Date,
        endDate: Date,
        locations: [LocationEventData],
        distanceMeters: Double,
        estimatedAverageSpeedMetersPerSecond: Double? = nil
    ) {
        self.localDateKey = localDateKey
        self.startDate = startDate
        self.endDate = endDate
        self.locations = locations
        self.distanceMeters = distanceMeters
        self.estimatedAverageSpeedMetersPerSecond = estimatedAverageSpeedMetersPerSecond
    }

    var durationSeconds: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}

nonisolated struct GapCandidate: Sendable, Equatable {
    let precedingLocation: LocationEventData
    let followingLocation: LocationEventData
    let reason: SegmentationBoundaryReason

    var durationSeconds: TimeInterval {
        followingLocation.timestamp.timeIntervalSince(precedingLocation.timestamp)
    }
}

nonisolated enum SegmentationBoundaryReason: Sendable, Equatable {
    case continuousGap
    case localDayBoundary
    case stationaryStay
    case visit
    case motionTransition
}
