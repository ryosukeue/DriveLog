enum StayDetectionSource: Sendable, Equatable {
    case visit
    case locationGap
    case motionTransition
    case combined
}
