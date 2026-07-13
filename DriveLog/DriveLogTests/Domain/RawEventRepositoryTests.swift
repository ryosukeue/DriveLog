@testable import DriveLog
import Foundation
import Testing

@Suite("Raw event repository contract")
struct RawEventRepositoryTests {
    @Test("Save result exposes every designed case")
    func saveResultCases() {
        #expect(RawEventSaveResult.inserted != .updated)
        #expect(RawEventSaveResult.updated != .duplicateIgnored)
        #expect(RawEventSaveResult.duplicateIgnored != .inserted)
    }

    @Test("In-memory fake saves and returns events by local date")
    func fakeStoresEventsByDate() async throws {
        let repository = InMemoryRawEventRepository()
        let location = locationEvent(localDateKey: firstDateKey)
        let motion = motionEvent(localDateKey: firstDateKey)
        let visit = visitEvent(localDateKey: firstDateKey)

        #expect(try await repository.saveLocationEvent(location) == .inserted)
        #expect(try await repository.saveMotionEvent(motion) == .inserted)
        #expect(try await repository.saveOrUpdateVisitEvent(visit) == .inserted)
        _ = try await repository.saveLocationEvent(locationEvent(localDateKey: secondDateKey))

        let events = try await repository.rawEvents(for: firstDateKey)
        #expect(events.locations == [location])
        #expect(events.motions == [motion])
        #expect(events.visits == [visit])
        #expect(events.classificationOverrides.isEmpty)
        #expect(events.stayOverrides.isEmpty)
    }

    @Test("In-memory fake can produce configured save results")
    func fakeProducesConfiguredResults() async throws {
        let repository = InMemoryRawEventRepository(
            locationResult: .duplicateIgnored, motionResult: .updated, visitResult: .updated
        )

        #expect(
            try await repository.saveLocationEvent(locationEvent(localDateKey: firstDateKey))
                == .duplicateIgnored
        )
        #expect(
            try await repository.saveMotionEvent(motionEvent(localDateKey: firstDateKey)) == .updated
        )
        #expect(
            try await repository.saveOrUpdateVisitEvent(visitEvent(localDateKey: firstDateKey))
                == .updated
        )
    }

    @Test("Deleting one date preserves other dates")
    func fakeDeletesOnlyRequestedDate() async throws {
        let repository = InMemoryRawEventRepository()
        _ = try await repository.saveLocationEvent(locationEvent(localDateKey: firstDateKey))
        let retained = locationEvent(localDateKey: secondDateKey)
        _ = try await repository.saveLocationEvent(retained)

        try await repository.deleteRawEvents(for: firstDateKey)

        #expect(try await repository.rawEvents(for: firstDateKey) == .empty)
        #expect(try await repository.rawEvents(for: secondDateKey).locations == [retained])
    }

    private var firstDateKey: String {
        "2026-07-13"
    }

    private var secondDateKey: String {
        "2026-07-14"
    }

    private var date: Date {
        Date(timeIntervalSince1970: 1_700_000_000)
    }

    private func locationEvent(localDateKey: String) -> LocationEventData {
        LocationEventData(
            latitude: 35, longitude: 139, timestamp: date, horizontalAccuracy: 10,
            speedMetersPerSecond: nil, createdAt: date, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: localDateKey
        )
    }

    private func motionEvent(localDateKey: String) -> MotionEventData {
        MotionEventData(
            startDate: date, endDate: nil, isAutomotive: true, isWalking: false,
            isRunning: false, isCycling: false, isStationary: false, isUnknown: false,
            confidence: .high, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: localDateKey
        )
    }

    private func visitEvent(localDateKey: String) -> VisitEventData {
        VisitEventData(
            latitude: 35, longitude: 139, arrivalDate: date, departureDate: nil,
            horizontalAccuracy: 20, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: localDateKey
        )
    }
}
