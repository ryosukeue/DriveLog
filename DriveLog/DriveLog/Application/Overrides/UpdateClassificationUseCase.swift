import Foundation

nonisolated protocol UpdateClassificationUseCase: Sendable {
    func execute(
        segment: MovementSegmentData,
        classification: UserMovementClassification
    ) async throws
}

nonisolated struct DefaultUpdateClassificationUseCase: UpdateClassificationUseCase {
    private let overrideRepository: any OverrideRepository
    private let clock: any Clock

    init(overrideRepository: any OverrideRepository, clock: any Clock) {
        self.overrideRepository = overrideRepository
        self.clock = clock
    }

    func execute(
        segment: MovementSegmentData,
        classification: UserMovementClassification
    ) async throws {
        guard segment.localDateKey.isEmpty == false,
              segment.stableID.isEmpty == false,
              segment.startDate <= segment.endDate
        else { throw DriveLogError.invalidData }

        let now = clock.now
        try await overrideRepository.upsertClassificationOverride(
            ClassificationOverrideData(
                overrideKey: "\(segment.localDateKey)|\(segment.stableID)",
                targetStableID: segment.stableID,
                localDateKey: segment.localDateKey,
                originalStartDate: segment.startDate,
                originalEndDate: segment.endDate,
                userClassification: classification,
                createdAt: now,
                updatedAt: now
            )
        )
    }
}
