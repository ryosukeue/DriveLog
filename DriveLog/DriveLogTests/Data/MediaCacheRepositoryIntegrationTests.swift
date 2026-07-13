@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Media cache repository integration")
@MainActor
struct MediaCacheRepositoryIntegrationTests {
    private let validatedAt = Date(timeIntervalSince1970: 1_700_100_000)

    @Test("round trips photos without location and videos with location")
    func roundTrip() async throws {
        let (_, repository) = try makeRepository()
        let photo = media(id: "photo", dateOffset: 20)
        let video = media(id: "video", type: .video, dateOffset: 10, hasLocation: true)

        try await repository.upsertAssets([photo, video], for: "2024-01-01", validatedAt: validatedAt)
        let values = try await repository.cachedAssets(for: "2024-01-01")

        #expect(values == [video, photo])
        #expect(values.first?.location == RouteCoordinate(latitude: 35, longitude: 139))
        #expect(values.first?.durationSeconds == 30)
    }

    @Test("upsert keeps one row and accepts the last duplicate")
    func upsert() async throws {
        let (container, repository) = try makeRepository()
        let first = media(id: "same")
        let updated = media(id: "same", type: .video, dateOffset: 60, hasLocation: true)

        try await repository.upsertAssets(
            [first, updated],
            for: "2024-01-01",
            validatedAt: validatedAt
        )

        #expect(try await repository.cachedAssets(for: "2024-01-01") == [updated])
        let context = ModelContext(container)
        let models = try context.fetch(FetchDescriptor<MediaAssetCacheModel>())
        #expect(models.count == 1)
        #expect(models.first?.eligibilityRawValue == "eligible")
        #expect(models.first?.lastValidatedAt == validatedAt)
    }

    @Test("replace removes stale values and preserves other days")
    func replace() async throws {
        let (_, repository) = try makeRepository()
        try await repository.upsertAssets(
            [media(id: "stale"), media(id: "kept")],
            for: "2024-01-01",
            validatedAt: validatedAt
        )
        try await repository.upsertAssets(
            [media(id: "other")],
            for: "2024-01-02",
            validatedAt: validatedAt
        )
        let updated = media(id: "kept", type: .video, dateOffset: 100)
        try await repository.replaceAssets(
            for: "2024-01-01",
            assets: [updated, updated],
            validatedAt: validatedAt.addingTimeInterval(10)
        )

        #expect(try await repository.cachedAssets(for: "2024-01-01") == [updated])
        #expect(try await repository.cachedAssets(for: "2024-01-02").map(\.localIdentifier) == [
            "other"
        ])
    }

    @Test("remove and date deletion are scoped and idempotent")
    func removal() async throws {
        let (_, repository) = try makeRepository()
        try await repository.upsertAssets(
            [media(id: "one"), media(id: "two")],
            for: "2024-01-01",
            validatedAt: validatedAt
        )
        try await repository.upsertAssets(
            [media(id: "other")],
            for: "2024-01-02",
            validatedAt: validatedAt
        )
        try await repository.removeAssets(localIdentifiers: ["one", "missing", "one"])
        #expect(try await repository.cachedAssets(for: "2024-01-01").map(\.localIdentifier) == [
            "two"
        ])

        try await repository.deleteCache(for: "2024-01-01")
        try await repository.deleteCache(for: "2024-01-01")
        #expect(try await repository.cachedAssets(for: "2024-01-01").isEmpty)
        #expect(try await repository.cachedAssets(for: "2024-01-02").count == 1)
    }

    @Test("replace updates an existing aggregate media count")
    func aggregateCount() async throws {
        let (container, repository) = try makeRepository()
        let context = ModelContext(container)
        context.insert(aggregate(localDateKey: "2024-01-01", mediaCount: 9))
        context.insert(aggregate(localDateKey: "2024-01-02", mediaCount: 4))
        try context.save()

        try await repository.replaceAssets(
            for: "2024-01-01",
            assets: [media(id: "one"), media(id: "two")],
            validatedAt: validatedAt
        )

        let aggregates = try ModelContext(container).fetch(FetchDescriptor<DayAggregateModel>())
        #expect(aggregates.first { $0.localDateKey == "2024-01-01" }?.mediaCountCache == 2)
        #expect(aggregates.first { $0.localDateKey == "2024-01-02" }?.mediaCountCache == 4)
    }

    private func makeRepository() throws -> (ModelContainer, SwiftDataMediaCacheRepository) {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        return (container, SwiftDataMediaCacheRepository(modelContainer: container))
    }

    private func media(
        id: String,
        type: MediaType = .photo,
        dateOffset: TimeInterval = 0,
        hasLocation: Bool = false
    ) -> MediaAssetReference {
        MediaAssetReference(
            localIdentifier: id,
            mediaType: type,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000 + dateOffset),
            location: hasLocation ? RouteCoordinate(latitude: 35, longitude: 139) : nil,
            durationSeconds: type == .video ? 30 : nil,
            isScreenshot: false,
            isScreenRecording: false
        )
    }

    private func aggregate(localDateKey: String, mediaCount: Int) -> DayAggregateModel {
        DayAggregateModel(
            localDateKey: localDateKey,
            totalDistanceMeters: 0,
            totalMovementDurationSeconds: 0,
            startDate: nil,
            endDate: nil,
            locationRecordCount: 0,
            rejectedLocationCount: 0,
            mediaCountCache: mediaCount,
            automaticClassificationRawValue: "other",
            hasValidMovement: false,
            movementSegmentCount: 0,
            staySegmentCount: 0,
            totalStayDurationSeconds: 0,
            automotiveDurationSeconds: 0,
            walkingDurationSeconds: 0,
            sourceRawRevision: 0,
            generatedAt: validatedAt
        )
    }
}
