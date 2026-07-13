@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Location event repository integration")
@MainActor
struct LocationEventRepositoryIntegrationTests {
    @Test("inserts and retrieves locations by date in timestamp order")
    func insertAndRetrieveByDate() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let repository = SwiftDataRawEventRepository(modelContainer: container)

        #expect(try await repository.saveLocationEvent(event(seconds: 60)) == .inserted)
        #expect(try await repository.saveLocationEvent(event(seconds: 0)) == .inserted)
        #expect(
            try await repository.saveLocationEvent(event(seconds: 120, localDateKey: "2024-01-02"))
                == .inserted
        )

        let events = try await repository.locationEvents(for: "2024-01-01")
        #expect(events.map(\.timestamp) == [date, date.addingTimeInterval(60)])
    }

    @Test("ignores a near duplicate and does not increment raw revision")
    func duplicateIgnored() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let repository = SwiftDataRawEventRepository(modelContainer: container)

        #expect(try await repository.saveLocationEvent(event()) == .inserted)
        #expect(
            try await repository.saveLocationEvent(
                event(seconds: 30, latitudeMeters: 10, horizontalAccuracy: 20)
            ) == .duplicateIgnored
        )

        #expect(try processingState(in: container)?.rawRevision == 1)
        #expect(try await repository.locationEvents(for: key).count == 1)
    }

    @Test("updates a duplicate when incoming horizontal accuracy is better")
    func betterDuplicateUpdates() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let repository = SwiftDataRawEventRepository(modelContainer: container)

        #expect(
            try await repository.saveLocationEvent(event(horizontalAccuracy: 20)) == .inserted
        )
        let better = event(
            seconds: 10, latitudeMeters: 5, horizontalAccuracy: 5,
            speedMetersPerSecond: 3
        )
        #expect(try await repository.saveLocationEvent(better) == .updated)

        #expect(try await repository.locationEvents(for: key) == [better])
        #expect(try processingState(in: container)?.rawRevision == 2)
    }

    @Test("stores events outside either duplicate threshold")
    func outsideThresholdsInsert() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let repository = SwiftDataRawEventRepository(modelContainer: container)

        #expect(try await repository.saveLocationEvent(event()) == .inserted)
        #expect(
            try await repository.saveLocationEvent(event(seconds: 31, latitudeMeters: 5))
                == .inserted
        )
        #expect(
            try await repository.saveLocationEvent(event(seconds: 5, latitudeMeters: -11))
                == .inserted
        )

        #expect(try await repository.locationEvents(for: key).count == 3)
        #expect(try processingState(in: container)?.rawRevision == 3)
    }

    private var date: Date {
        Date(timeIntervalSince1970: 1_704_067_200)
    }

    private var key: String {
        "2024-01-01"
    }

    private func event(
        seconds: TimeInterval = 0,
        latitudeMeters: Double = 0,
        horizontalAccuracy: Double = 10,
        speedMetersPerSecond: Double? = nil,
        localDateKey: String = "2024-01-01"
    ) -> LocationEventData {
        LocationEventData(
            latitude: 35 + latitudeMeters / 111_195,
            longitude: 139,
            timestamp: date.addingTimeInterval(seconds),
            horizontalAccuracy: horizontalAccuracy,
            speedMetersPerSecond: speedMetersPerSecond,
            createdAt: date.addingTimeInterval(seconds + 100),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: localDateKey
        )
    }

    private func processingState(in container: ModelContainer) throws -> DayProcessingStateModel? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<DayProcessingStateModel>(
            predicate: #Predicate { $0.localDateKey == "2024-01-01" }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
