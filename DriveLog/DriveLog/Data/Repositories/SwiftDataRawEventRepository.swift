import SwiftData

struct SwiftDataRawEventRepository: Sendable {
    private let persistenceActor: PersistenceActor

    init(modelContainer: ModelContainer) {
        persistenceActor = PersistenceActor(modelContainer: modelContainer)
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
}
