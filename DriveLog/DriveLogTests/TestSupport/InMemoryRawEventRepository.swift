@testable import DriveLog

actor InMemoryRawEventRepository: RawEventRepository {
    private var locations: [LocationEventData] = []
    private var motions: [MotionEventData] = []
    private var visits: [VisitEventData] = []
    private let locationResult: RawEventSaveResult
    private let motionResult: RawEventSaveResult
    private let visitResult: RawEventSaveResult

    init(
        locationResult: RawEventSaveResult = .inserted,
        motionResult: RawEventSaveResult = .inserted,
        visitResult: RawEventSaveResult = .inserted
    ) {
        self.locationResult = locationResult
        self.motionResult = motionResult
        self.visitResult = visitResult
    }

    func saveLocationEvent(_ event: LocationEventData) -> RawEventSaveResult {
        locations.append(event)
        return locationResult
    }

    func saveMotionEvent(_ event: MotionEventData) -> RawEventSaveResult {
        motions.append(event)
        return motionResult
    }

    func saveOrUpdateVisitEvent(_ event: VisitEventData) -> RawEventSaveResult {
        visits.append(event)
        return visitResult
    }

    func rawEvents(for localDateKey: String) -> RawDayEvents {
        RawDayEvents(
            locations: locations.filter { $0.localDateKey == localDateKey },
            motions: motions.filter { $0.localDateKey == localDateKey },
            visits: visits.filter { $0.localDateKey == localDateKey },
            classificationOverrides: [], stayOverrides: []
        )
    }

    func deleteRawEvents(for localDateKey: String) {
        locations.removeAll { $0.localDateKey == localDateKey }
        motions.removeAll { $0.localDateKey == localDateKey }
        visits.removeAll { $0.localDateKey == localDateKey }
    }
}
