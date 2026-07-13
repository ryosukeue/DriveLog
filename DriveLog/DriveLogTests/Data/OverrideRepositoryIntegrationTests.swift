@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Override repository integration")
@MainActor
struct OverrideRepositoryIntegrationTests {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("stores both override types by local date")
    func storesAndFetches() async throws {
        let repository = try makeRepository()
        try await repository.upsertClassificationOverride(classification(id: "movement"))
        try await repository.upsertStayOverride(stay(id: "stay"))
        try await repository.upsertClassificationOverride(
            classification(id: "other", day: "2024-01-02")
        )

        #expect(try await repository.classificationOverrides(for: "2024-01-01").count == 1)
        #expect(try await repository.stayOverrides(for: "2024-01-01").count == 1)
        #expect(try await repository.classificationOverrides(for: "2024-01-02").count == 1)
    }

    @Test("updates an existing key without replacing creation data")
    func upserts() async throws {
        let repository = try makeRepository()
        let original = classification(id: "movement")
        let updated = ClassificationOverrideData(
            overrideKey: original.overrideKey, targetStableID: original.targetStableID,
            localDateKey: original.localDateKey, originalStartDate: original.originalStartDate,
            originalEndDate: original.originalEndDate, userClassification: .walking,
            createdAt: date.addingTimeInterval(10), updatedAt: date.addingTimeInterval(20)
        )
        try await repository.upsertClassificationOverride(original)
        try await repository.upsertClassificationOverride(updated)

        let values = try await repository.classificationOverrides(for: "2024-01-01")
        #expect(values.count == 1)
        #expect(values.first?.userClassification == .walking)
        #expect(values.first?.createdAt == date)
        #expect(values.first?.updatedAt == date.addingTimeInterval(20))
    }

    @Test("rejects invalid keys and deletes only the requested day")
    func validationAndDeletion() async throws {
        let repository = try makeRepository()
        let invalid = ClassificationOverrideData(
            overrideKey: "invalid", targetStableID: "movement", localDateKey: "2024-01-01",
            originalStartDate: date, originalEndDate: date.addingTimeInterval(60),
            userClassification: .automotive, createdAt: date, updatedAt: date
        )
        await #expect(throws: DriveLogError.persistenceFailure(
            code: "upsert_classification_override"
        )) {
            try await repository.upsertClassificationOverride(invalid)
        }
        try await repository.upsertClassificationOverride(classification(id: "one"))
        try await repository.upsertStayOverride(stay(id: "one"))
        try await repository.upsertStayOverride(stay(id: "two", day: "2024-01-02"))
        try await repository.deleteOverrides(for: "2024-01-01")
        try await repository.deleteOverrides(for: "2024-01-01")

        #expect(try await repository.classificationOverrides(for: "2024-01-01").isEmpty)
        #expect(try await repository.stayOverrides(for: "2024-01-01").isEmpty)
        #expect(try await repository.stayOverrides(for: "2024-01-02").count == 1)
    }

    private func makeRepository() throws -> SwiftDataOverrideRepository {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        return SwiftDataOverrideRepository(modelContainer: container)
    }

    private func classification(
        id: String,
        day: String = "2024-01-01"
    ) -> ClassificationOverrideData {
        ClassificationOverrideData(
            overrideKey: "\(day)|\(id)", targetStableID: id, localDateKey: day,
            originalStartDate: date, originalEndDate: date.addingTimeInterval(60),
            userClassification: .automotive, createdAt: date, updatedAt: date
        )
    }

    private func stay(id: String, day: String = "2024-01-01") -> StayOverrideData {
        StayOverrideData(
            overrideKey: "\(day)|\(id)", targetStableID: id, localDateKey: day,
            originalArrivalDate: date, originalDepartureDate: date.addingTimeInterval(60),
            originalCoordinate: RouteCoordinate(latitude: 35, longitude: 139), action: .confirm,
            createdAt: date, updatedAt: date
        )
    }
}
