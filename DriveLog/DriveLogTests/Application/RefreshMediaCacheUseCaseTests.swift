import AVFoundation
@testable import DriveLog
import Foundation
import Testing
import UIKit

@Suite("Refresh media cache use case")
struct RefreshMediaCacheUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_710_000_000)

    @Test("builds a DST-aware interval, filters, sorts, replaces, and logs")
    func refresh() async throws {
        let timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let firstDate = Date(timeIntervalSince1970: 1_710_068_400)
        let secondDate = firstDate.addingTimeInterval(60)
        let photoLibrary = FakePhotoLibraryProvider(authorization: .limited, assets: [
            media(id: "b", date: firstDate),
            media(id: "screen", date: firstDate, isScreenshot: true),
            media(id: "a", date: firstDate),
            media(id: "recording", date: secondDate, isScreenRecording: true),
            media(id: "missing-date", date: nil),
            media(id: "later", date: secondDate)
        ])
        let repository = MediaCacheRepositorySpy()
        let logger = SpyEventLogger()
        let useCase = makeUseCase(
            photoLibrary: photoLibrary,
            repository: repository,
            timeZone: timeZone,
            logger: logger
        )

        let result = try await useCase.execute(localDateKey: "2024-03-10")

        #expect(result.map(\.localIdentifier) == ["a", "b", "later"])
        #expect(result.allSatisfy { $0.location == nil })
        let interval = try #require(photoLibrary.fetchedIntervals.first)
        #expect(interval.duration == 23 * 60 * 60)
        #expect(photoLibrary.fetchedIntervals.count == 1)
        let replacement = try #require(await repository.replacements.first)
        #expect(replacement.localDateKey == "2024-03-10")
        #expect(replacement.assets == result)
        #expect(replacement.validatedAt == now)
        #expect(logger.records == [
            TestLogRecord(
                level: .info,
                event: .mediaPlacementDiagnosed(
                    permissionCode: "limited",
                    fetchedCount: 6,
                    eligibleCount: 3,
                    locatedCount: 0
                )
            ),
            TestLogRecord(
                level: .info,
                event: .mediaCacheRefreshed(localDateKey: "2024-03-10", count: 3)
            )
        ])
    }

    @Test("empty limited result replaces stale day cache")
    func emptyResult() async throws {
        let photoLibrary = FakePhotoLibraryProvider(authorization: .limited)
        let repository = MediaCacheRepositorySpy()
        let logger = SpyEventLogger()

        let result = try await makeUseCase(
            photoLibrary: photoLibrary,
            repository: repository,
            timeZone: #require(TimeZone(identifier: "Asia/Tokyo")),
            logger: logger
        ).execute(localDateKey: "2024-01-02")

        #expect(result.isEmpty)
        #expect(await repository.replacements.first?.assets.isEmpty == true)
        #expect(logger.records.map(\.event) == [
            .mediaPlacementDiagnosed(
                permissionCode: "limited",
                fetchedCount: 0,
                eligibleCount: 0,
                locatedCount: 0
            ),
            .mediaCacheRefreshed(localDateKey: "2024-01-02", count: 0)
        ])
    }

    @Test("invalid date does not fetch, replace, or log", arguments: [
        "2024-02-30", "2024-13-01", "2024-1-01", "invalid"
    ])
    func invalidDate(localDateKey: String) async throws {
        let photoLibrary = FakePhotoLibraryProvider()
        let repository = MediaCacheRepositorySpy()
        let logger = SpyEventLogger()
        let useCase = try makeUseCase(
            photoLibrary: photoLibrary,
            repository: repository,
            timeZone: #require(TimeZone(identifier: "UTC")),
            logger: logger
        )

        await #expect(throws: DriveLogError.invalidData) {
            try await useCase.execute(localDateKey: localDateKey)
        }
        #expect(photoLibrary.fetchedIntervals.isEmpty)
        #expect(await repository.replacements.isEmpty)
        #expect(logger.records.isEmpty)
    }

    @Test("photo fetch failure is preserved without replacing or logging")
    func fetchFailure() async throws {
        let photoLibrary = FakePhotoLibraryProvider(error: .mediaAccessLimited)
        let repository = MediaCacheRepositorySpy()
        let logger = SpyEventLogger()
        let useCase = try makeUseCase(
            photoLibrary: photoLibrary,
            repository: repository,
            timeZone: #require(TimeZone(identifier: "UTC")),
            logger: logger
        )

        await #expect(throws: DriveLogError.mediaAccessLimited) {
            try await useCase.execute(localDateKey: "2024-01-01")
        }
        #expect(await repository.replacements.isEmpty)
        #expect(logger.records.isEmpty)
    }

    @Test("repository failure is preserved without success log")
    func repositoryFailure() async throws {
        let expected = DriveLogError.persistenceFailure(code: "replace_media_cache")
        let repository = MediaCacheRepositorySpy(error: expected)
        let logger = SpyEventLogger()
        let useCase = try makeUseCase(
            photoLibrary: FakePhotoLibraryProvider(assets: [media(
                id: "photo",
                date: now
            )]),
            repository: repository,
            timeZone: #require(TimeZone(identifier: "UTC")),
            logger: logger
        )

        await #expect(throws: expected) {
            try await useCase.execute(localDateKey: "2024-03-09")
        }
        #expect(logger.records.map(\.event) == [
            .mediaPlacementDiagnosed(
                permissionCode: "authorized",
                fetchedCount: 1,
                eligibleCount: 1,
                locatedCount: 0
            )
        ])
    }

    private func makeUseCase(
        photoLibrary: FakePhotoLibraryProvider,
        repository: MediaCacheRepositorySpy,
        timeZone: TimeZone,
        logger: SpyEventLogger
    ) -> DefaultRefreshMediaCacheUseCase {
        DefaultRefreshMediaCacheUseCase(
            photoLibrary: photoLibrary,
            eligibilityEvaluator: DefaultMediaEligibilityEvaluator(),
            mediaCacheRepository: repository,
            clock: FixedMediaClock(now: now),
            timeZoneProvider: FixedMediaTimeZoneProvider(current: timeZone),
            logger: logger
        )
    }

    private func media(
        id: String,
        date: Date?,
        isScreenshot: Bool = false,
        isScreenRecording: Bool = false
    ) -> MediaAssetReference {
        MediaAssetReference(
            localIdentifier: id,
            mediaType: isScreenRecording ? .video : .photo,
            creationDate: date,
            location: nil,
            durationSeconds: isScreenRecording ? 30 : nil,
            isScreenshot: isScreenshot,
            isScreenRecording: isScreenRecording
        )
    }
}

private struct FixedMediaClock: Clock {
    let now: Date
}

private struct FixedMediaTimeZoneProvider: TimeZoneProviding {
    let current: TimeZone
}

private actor MediaCacheRepositorySpy: MediaCacheRepository {
    struct Replacement: Sendable, Equatable {
        let localDateKey: String
        let assets: [MediaAssetReference]
        let validatedAt: Date
    }

    private(set) var replacements: [Replacement] = []
    private let error: DriveLogError?

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func cachedAssets(for _: String) async throws -> [MediaAssetReference] {
        []
    }

    func upsertAssets(_: [MediaAssetReference], for _: String, validatedAt _: Date) async throws {}

    func removeAssets(localIdentifiers _: [String]) async throws {}

    func replaceAssets(
        for localDateKey: String,
        assets: [MediaAssetReference],
        validatedAt: Date
    ) async throws {
        if let error {
            throw error
        }
        replacements.append(Replacement(
            localDateKey: localDateKey,
            assets: assets,
            validatedAt: validatedAt
        ))
    }

    func deleteCache(for _: String) async throws {}
}
