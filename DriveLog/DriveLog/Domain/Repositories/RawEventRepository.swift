protocol RawEventRepository: Sendable {
    func saveLocationEvent(_ event: LocationEventData) async throws -> RawEventSaveResult
    func saveMotionEvent(_ event: MotionEventData) async throws -> RawEventSaveResult
    func saveOrUpdateVisitEvent(_ event: VisitEventData) async throws -> RawEventSaveResult
    func rawEvents(for localDateKey: String) async throws -> RawDayEvents
    func deleteRawEvents(for localDateKey: String) async throws
}

nonisolated enum RawEventSaveResult: Sendable, Equatable {
    case inserted
    case updated
    case duplicateIgnored
}
