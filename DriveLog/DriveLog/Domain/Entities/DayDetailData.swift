nonisolated struct DayDetailData: Sendable {
    let aggregate: DayAggregateData
    let movements: [MovementDisplayData]
    let stays: [StayDisplayData]
    let media: [MediaAssetReference]
    let mapScene: MapScene
    let isReprocessing: Bool
}

nonisolated struct MovementDisplayData: Sendable, Equatable {
    let segment: MovementSegmentData
    let userClassification: UserMovementClassification?
}

nonisolated struct StayDisplayData: Sendable, Equatable {
    let segment: StaySegmentData
    let overrideAction: StayOverrideAction?

    var isVisible: Bool {
        switch overrideAction {
        case .confirm:
            true
        case .hide:
            false
        case .automatic, nil:
            segment.isVisibleByAutomaticRule
        }
    }
}
