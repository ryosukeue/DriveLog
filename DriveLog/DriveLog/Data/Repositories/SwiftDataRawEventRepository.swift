import SwiftData

struct SwiftDataRawEventRepository: Sendable {
    private let persistenceActor: PersistenceActor
    private let clock: any Clock

    init(modelContainer: ModelContainer, clock: any Clock = SystemClock()) {
        persistenceActor = PersistenceActor(modelContainer: modelContainer)
        self.clock = clock
    }

    func saveLocationEvent(_ event: LocationEventData) async throws -> RawEventSaveResult {
        do {
            return try await persistenceActor.saveLocationEvent(event)
        } catch {
            throw DriveLogError.persistenceFailure(code: "save_location_event")
        }
    }

    func locationEvents(for localDateKey: String) async throws -> [LocationEventData] {
        do {
            return try await persistenceActor.locationEvents(for: localDateKey)
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_location_events")
        }
    }

    func saveMotionEvent(_ event: MotionEventData) async throws -> RawEventSaveResult {
        do {
            return try await persistenceActor.saveMotionEvent(event, createdAt: clock.now)
        } catch {
            throw DriveLogError.persistenceFailure(code: "save_motion_event")
        }
    }

    func motionEvents(for localDateKey: String) async throws -> [MotionEventData] {
        do {
            return try await persistenceActor.motionEvents(for: localDateKey)
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_motion_events")
        }
    }
}
