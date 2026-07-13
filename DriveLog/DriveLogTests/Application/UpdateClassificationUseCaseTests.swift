@testable import DriveLog
import Foundation
import Testing

@Suite("Update classification use case")
struct UpdateClassificationUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_710_000_000)

    @Test("creates an override for every user classification", arguments: [
        UserMovementClassification.automotive,
        .train,
        .bus,
        .walking,
        .other
    ])
    func classifications(classification: UserMovementClassification) async throws {
        let repository = ClassificationOverrideRepositorySpy()
        let segment = makeSegment()
        let useCase = DefaultUpdateClassificationUseCase(
            overrideRepository: repository,
            clock: ClassificationFixedClock(now: now)
        )

        try await useCase.execute(segment: segment, classification: classification)

        let saved = try #require(await repository.values.first)
        #expect(saved.overrideKey == "2024-03-09|segment-1")
        #expect(saved.targetStableID == segment.stableID)
        #expect(saved.localDateKey == segment.localDateKey)
        #expect(saved.originalStartDate == segment.startDate)
        #expect(saved.originalEndDate == segment.endDate)
        #expect(saved.userClassification == classification)
        #expect(saved.createdAt == now)
        #expect(saved.updatedAt == now)
        #expect(segment.automaticClassification == .automotiveLike)
    }

    @Test("repeated edits use the same override key")
    func repeatedEdit() async throws {
        let repository = ClassificationOverrideRepositorySpy()
        let useCase = DefaultUpdateClassificationUseCase(
            overrideRepository: repository,
            clock: ClassificationFixedClock(now: now)
        )
        let segment = makeSegment()

        try await useCase.execute(segment: segment, classification: .train)
        try await useCase.execute(segment: segment, classification: .bus)

        let values = await repository.values
        #expect(values.map(\.overrideKey) == [
            "2024-03-09|segment-1",
            "2024-03-09|segment-1"
        ])
        #expect(values.map(\.userClassification) == [.train, .bus])
    }

    @Test("invalid segment is rejected before persistence", arguments: [
        ("", "segment", 0.0, 60.0),
        ("2024-03-09", "", 0.0, 60.0),
        ("2024-03-09", "segment", 60.0, 0.0)
    ])
    func invalidSegment(
        localDateKey: String,
        stableID: String,
        start: TimeInterval,
        end: TimeInterval
    ) async {
        let repository = ClassificationOverrideRepositorySpy()
        let useCase = DefaultUpdateClassificationUseCase(
            overrideRepository: repository,
            clock: ClassificationFixedClock(now: now)
        )

        await #expect(throws: DriveLogError.invalidData) {
            try await useCase.execute(
                segment: makeSegment(
                    localDateKey: localDateKey,
                    stableID: stableID,
                    start: start,
                    end: end
                ),
                classification: .other
            )
        }
        #expect(await repository.values.isEmpty)
    }

    @Test("repository failure is preserved")
    func repositoryFailure() async {
        let expected = DriveLogError.persistenceFailure(code: "upsert")
        let repository = ClassificationOverrideRepositorySpy(error: expected)
        let useCase = DefaultUpdateClassificationUseCase(
            overrideRepository: repository,
            clock: ClassificationFixedClock(now: now)
        )

        await #expect(throws: expected) {
            try await useCase.execute(segment: makeSegment(), classification: .walking)
        }
    }

    private func makeSegment(
        localDateKey: String = "2024-03-09",
        stableID: String = "segment-1",
        start: TimeInterval = 100,
        end: TimeInterval = 200
    ) -> MovementSegmentData {
        MovementSegmentData(
            stableID: stableID,
            localDateKey: localDateKey,
            startDate: Date(timeIntervalSince1970: start),
            endDate: Date(timeIntervalSince1970: end),
            distanceMeters: 1000,
            durationSeconds: end - start,
            estimatedAverageSpeedMetersPerSecond: 10,
            automaticClassification: .automotiveLike,
            classificationConfidence: .high,
            route: [],
            labelCoordinate: nil,
            sourceRawRevision: 1,
            generatedAt: now
        )
    }
}

private struct ClassificationFixedClock: Clock {
    let now: Date
}

private actor ClassificationOverrideRepositorySpy: OverrideRepository {
    private(set) var values: [ClassificationOverrideData] = []
    private let error: DriveLogError?

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func classificationOverrides(for _: String) -> [ClassificationOverrideData] {
        []
    }

    func stayOverrides(for _: String) -> [StayOverrideData] {
        []
    }

    func upsertClassificationOverride(_ value: ClassificationOverrideData) throws {
        if let error {
            throw error
        }
        values.append(value)
    }

    func upsertStayOverride(_: StayOverrideData) {}

    func deleteOverrides(for _: String) {}
}
