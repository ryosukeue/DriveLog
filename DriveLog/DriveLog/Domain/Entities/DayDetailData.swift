nonisolated struct DayDetailData: Sendable {
    let aggregate: DayAggregateData
    let movements: [MovementDisplayData]
    let stays: [StayDisplayData]
    let media: [MediaAssetReference]
    let mapScene: MapScene
    let isReprocessing: Bool
    let vehicleDistances: [VehicleDistanceSummary]

    init(
        aggregate: DayAggregateData,
        movements: [MovementDisplayData],
        stays: [StayDisplayData],
        media: [MediaAssetReference],
        mapScene: MapScene,
        isReprocessing: Bool,
        vehicleDistances: [VehicleDistanceSummary] = []
    ) {
        self.aggregate = aggregate
        self.movements = movements
        self.stays = stays
        self.media = media
        self.mapScene = mapScene
        self.isReprocessing = isReprocessing
        self.vehicleDistances = vehicleDistances
    }
}

nonisolated struct MovementDisplayData: Sendable, Equatable {
    let segment: MovementSegmentData
    let userClassification: UserMovementClassification?
    let vehicle: VehicleProfile?

    init(
        segment: MovementSegmentData,
        userClassification: UserMovementClassification?,
        vehicle: VehicleProfile? = nil
    ) {
        self.segment = segment
        self.userClassification = userClassification
        self.vehicle = vehicle
    }
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
