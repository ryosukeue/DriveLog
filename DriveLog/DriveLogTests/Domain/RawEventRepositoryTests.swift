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
    func fakeStoresEventsByDate() async {
        let repository = InMemoryRawEventRepository()
        let location = locationEvent(localDateKey: firstDateKey)
        let motion = motionEvent(localDateKey: firstDateKey)
        let visit = visitEvent(localDateKey: firstDateKey)

        #expect(await repository.saveLocationEvent(location) == .inserted)
        #expect(await repository.saveMotionEvent(motion) == .inserted)
        #expect(await repository.saveOrUpdateVisitEvent(visit) == .inserted)
        _ = await repository.saveLocationEvent(locationEvent(localDateKey: secondDateKey))

        let events = await repository.rawEvents(for: firstDateKey)
        #expect(events.locations == [location])
        #expect(events.motions == [motion])
        #expect(events.visits == [visit])
        #expect(events.classificationOverrides.isEmpty)
        #expect(events.stayOverrides.isEmpty)
    }

    @Test("In-memory fake can produce configured save results")
    func fakeProducesConfiguredResults() async {
        let repository = InMemoryRawEventRepository(
            locationResult: .duplicateIgnored, motionResult: .updated, visitResult: .updated
        )

        #expect(
            await repository.saveLocationEvent(locationEvent(localDateKey: firstDateKey))
                == .duplicateIgnored
        )
        #expect(
            await repository.saveMotionEvent(motionEvent(localDateKey: firstDateKey)) == .updated
        )
        #expect(
            await repository.saveOrUpdateVisitEvent(visitEvent(localDateKey: firstDateKey))
                == .updated
        )
    }

    @Test("Deleting one date preserves other dates")
    func fakeDeletesOnlyRequestedDate() async {
        let repository = InMemoryRawEventRepository()
        _ = await repository.saveLocationEvent(locationEvent(localDateKey: firstDateKey))
        let retained = locationEvent(localDateKey: secondDateKey)
        _ = await repository.saveLocationEvent(retained)

        await repository.deleteRawEvents(for: firstDateKey)

        #expect(await repository.rawEvents(for: firstDateKey) == .empty)
        #expect(await repository.rawEvents(for: secondDateKey).locations == [retained])
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
