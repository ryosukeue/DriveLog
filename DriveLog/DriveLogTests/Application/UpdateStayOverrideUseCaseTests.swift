@testable import DriveLog
import Foundation
import Testing

@Suite("Update stay override use case")
struct UpdateStayOverrideUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_710_000_000)

    @Test("creates an override for every stay action", arguments: [
        StayOverrideAction.confirm,
        .hide,
        .automatic
    ])
    func actions(action: StayOverrideAction) async throws {
        let repository = StayOverrideRepositorySpy()
        let stay = makeStay()
        let useCase = DefaultUpdateStayOverrideUseCase(
            overrideRepository: repository,
            clock: StayOverrideFixedClock(now: now)
        )

        try await useCase.execute(stay: stay, action: action)

        let saved = try #require(await repository.values.first)
        #expect(saved.overrideKey == "2024-03-09|stay-1")
        #expect(saved.targetStableID == stay.stableID)
        #expect(saved.localDateKey == stay.localDateKey)
        #expect(saved.originalArrivalDate == stay.estimatedArrivalDate)
        #expect(saved.originalDepartureDate == stay.estimatedDepartureDate)
        #expect(saved.originalCoordinate == stay.representativeCoordinate)
        #expect(saved.action == action)
        #expect(saved.createdAt == now)
        #expect(saved.updatedAt == now)
        #expect(stay.isVisibleByAutomaticRule == false)
    }

    @Test("repeated edits use the same override key")
    func repeatedEdit() async throws {
        let repository = StayOverrideRepositorySpy()
        let useCase = DefaultUpdateStayOverrideUseCase(
            overrideRepository: repository,
            clock: StayOverrideFixedClock(now: now)
        )
        let stay = makeStay()

        try await useCase.execute(stay: stay, action: .confirm)
        try await useCase.execute(stay: stay, action: .automatic)

        let values = await repository.values
        #expect(values.map(\.overrideKey) == ["2024-03-09|stay-1", "2024-03-09|stay-1"])
        #expect(values.map(\.action) == [.confirm, .automatic])
    }

    @Test("invalid stay is rejected before persistence", arguments: [
        ("", "stay", 0.0, 60.0),
        ("2024-03-09", "", 0.0, 60.0),
        ("2024-03-09", "stay", 60.0, 0.0)
    ])
    func invalidStay(
        localDateKey: String,
        stableID: String,
        arrival: TimeInterval,
        departure: TimeInterval
    ) async {
        let repository = StayOverrideRepositorySpy()
        let useCase = DefaultUpdateStayOverrideUseCase(
            overrideRepository: repository,
            clock: StayOverrideFixedClock(now: now)
        )

        await #expect(throws: DriveLogError.invalidData) {
            try await useCase.execute(
                stay: makeStay(
                    localDateKey: localDateKey,
                    stableID: stableID,
                    arrival: arrival,
                    departure: departure
                ),
                action: .hide
            )
        }
        #expect(await repository.values.isEmpty)
    }

    @Test("repository failure is preserved")
    func repositoryFailure() async {
        let expected = DriveLogError.persistenceFailure(code: "upsert")
        let repository = StayOverrideRepositorySpy(error: expected)
        let useCase = DefaultUpdateStayOverrideUseCase(
            overrideRepository: repository,
            clock: StayOverrideFixedClock(now: now)
        )

        await #expect(throws: expected) {
            try await useCase.execute(stay: makeStay(), action: .confirm)
        }
    }

    private func makeStay(
        localDateKey: String = "2024-03-09",
        stableID: String = "stay-1",
        arrival: TimeInterval = 100,
        departure: TimeInterval = 200
    ) -> StaySegmentData {
        StaySegmentData(
            stableID: stableID,
            localDateKey: localDateKey,
            representativeCoordinate: RouteCoordinate(latitude: 35, longitude: 139),
            estimatedArrivalDate: Date(timeIntervalSince1970: arrival),
            estimatedDepartureDate: Date(timeIntervalSince1970: departure),
            durationSeconds: departure - arrival,
            confidence: .medium,
            source: .combined,
            isVisibleByAutomaticRule: false,
            sourceRawRevision: 1,
            generatedAt: now
        )
    }
}

private struct StayOverrideFixedClock: Clock {
    let now: Date
}

private actor StayOverrideRepositorySpy: OverrideRepository {
    private(set) var values: [StayOverrideData] = []
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

    func upsertClassificationOverride(_: ClassificationOverrideData) {}

    func upsertStayOverride(_ value: StayOverrideData) throws {
        if let error {
            throw error
        }
        values.append(value)
    }

    func deleteOverrides(for _: String) {}
}
