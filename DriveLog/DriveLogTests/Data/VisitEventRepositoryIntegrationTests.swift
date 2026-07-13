@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Visit event repository integration")
@MainActor
struct VisitEventRepositoryIntegrationTests {
    @Test("stores arrival-only and updates the same visit departure")
    func arrivalThenDeparture() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let arrivalRepository = SwiftDataRawEventRepository(
            modelContainer: container,
            clock: FixedVisitClock(now: date.addingTimeInterval(500))
        )
        let departureRepository = SwiftDataRawEventRepository(
            modelContainer: container,
            clock: FixedVisitClock(now: date.addingTimeInterval(600))
        )
        let arrival = visit()
        let departed = visit(
            arrivalSeconds: 30, latitudeMeters: 8,
            departureDate: date.addingTimeInterval(1800)
        )

        #expect(try await arrivalRepository.saveOrUpdateVisitEvent(arrival) == .inserted)
        #expect(try await departureRepository.saveOrUpdateVisitEvent(departed) == .updated)

        let raw = try await departureRepository.rawEvents(for: key)
        #expect(raw.visits.count == 1)
        #expect(raw.visits.first?.departureDate == departed.departureDate)
        #expect(try processingState(in: container)?.rawRevision == 2)
        let persisted = try #require(try visitModels(in: container).first)
        #expect(persisted.createdAt == date.addingTimeInterval(500))
        #expect(persisted.updatedAt == date.addingTimeInterval(600))
    }

    @Test("ignores a repeated visit without material changes")
    func duplicateIgnored() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let repository = SwiftDataRawEventRepository(
            modelContainer: container,
            clock: FixedVisitClock(now: date)
        )

        #expect(try await repository.saveOrUpdateVisitEvent(visit()) == .inserted)
        #expect(try await repository.saveOrUpdateVisitEvent(visit()) == .duplicateIgnored)
        #expect(try processingState(in: container)?.rawRevision == 1)
    }

    @Test("inserts visits outside arrival or distance threshold")
    func outsideThresholds() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let repository = SwiftDataRawEventRepository(
            modelContainer: container,
            clock: FixedVisitClock(now: date)
        )

        #expect(try await repository.saveOrUpdateVisitEvent(visit()) == .inserted)
        #expect(
            try await repository.saveOrUpdateVisitEvent(visit(arrivalSeconds: 61)) == .inserted
        )
        #expect(
            try await repository.saveOrUpdateVisitEvent(visit(latitudeMeters: -51)) == .inserted
        )
        #expect(try await repository.rawEvents(for: key).visits.count == 3)
    }

    @Test("returns and deletes all raw event types by date only")
    func rawEventsAndDelete() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let repository = SwiftDataRawEventRepository(
            modelContainer: container,
            clock: FixedVisitClock(now: date)
        )

        #expect(try await repository.saveLocationEvent(location()) == .inserted)
        #expect(try await repository.saveMotionEvent(motion()) == .inserted)
        #expect(try await repository.saveOrUpdateVisitEvent(visit()) == .inserted)
        #expect(
            try await repository.saveOrUpdateVisitEvent(visit(localDateKey: "2024-01-02"))
                == .inserted
        )
        let raw = try await repository.rawEvents(for: key)
        #expect(raw.locations.count == 1)
        #expect(raw.motions.count == 1)
        #expect(raw.visits.count == 1)

        try await repository.deleteRawEvents(for: key)

        #expect(try await repository.rawEvents(for: key) == .empty)
        #expect(try await repository.rawEvents(for: "2024-01-02").visits.count == 1)
    }

    private var date: Date {
        Date(timeIntervalSince1970: 1_704_067_200)
    }

    private var key: String {
        "2024-01-01"
    }

    private func visit(
        arrivalSeconds: TimeInterval = 0,
        latitudeMeters: Double = 0,
        departureDate: Date? = nil,
        localDateKey: String = "2024-01-01"
    ) -> VisitEventData {
        VisitEventData(
            latitude: 35 + latitudeMeters / 111_195, longitude: 139,
            arrivalDate: date.addingTimeInterval(arrivalSeconds),
            departureDate: departureDate, horizontalAccuracy: 50,
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: localDateKey
        )
    }

    private func location() -> LocationEventData {
        LocationEventData(
            latitude: 35, longitude: 139, timestamp: date, horizontalAccuracy: 10,
            speedMetersPerSecond: nil, createdAt: date, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: key
        )
    }

    private func motion() -> MotionEventData {
        MotionEventData(
            startDate: date, endDate: nil, isAutomotive: false, isWalking: true,
            isRunning: false, isCycling: false, isStationary: false, isUnknown: false,
            confidence: .high, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: key
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

    private func visitModels(in container: ModelContainer) throws -> [VisitEventModel] {
        try ModelContext(container).fetch(FetchDescriptor<VisitEventModel>())
    }
}

private struct FixedVisitClock: Clock {
    let now: Date
}
