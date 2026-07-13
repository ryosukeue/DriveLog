import Foundation

nonisolated protocol UpdateStayOverrideUseCase: Sendable {
    func execute(stay: StaySegmentData, action: StayOverrideAction) async throws
}

nonisolated struct DefaultUpdateStayOverrideUseCase: UpdateStayOverrideUseCase {
    private let overrideRepository: any OverrideRepository
    private let clock: any Clock

    init(overrideRepository: any OverrideRepository, clock: any Clock) {
        self.overrideRepository = overrideRepository
        self.clock = clock
    }

    func execute(stay: StaySegmentData, action: StayOverrideAction) async throws {
        guard stay.localDateKey.isEmpty == false,
              stay.stableID.isEmpty == false,
              stay.estimatedArrivalDate <= stay.estimatedDepartureDate
        else { throw DriveLogError.invalidData }

        let now = clock.now
        try await overrideRepository.upsertStayOverride(
            StayOverrideData(
                overrideKey: "\(stay.localDateKey)|\(stay.stableID)",
                targetStableID: stay.stableID,
                localDateKey: stay.localDateKey,
                originalArrivalDate: stay.estimatedArrivalDate,
                originalDepartureDate: stay.estimatedDepartureDate,
                originalCoordinate: stay.representativeCoordinate,
                action: action,
                createdAt: now,
                updatedAt: now
            )
        )
    }
}
