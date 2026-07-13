nonisolated struct RawDayEvents: Sendable, Equatable {
    let locations: [LocationEventData]
    let motions: [MotionEventData]
    let visits: [VisitEventData]
    let classificationOverrides: [ClassificationOverrideData]
    let stayOverrides: [StayOverrideData]

    static let empty = RawDayEvents(
        locations: [], motions: [], visits: [], classificationOverrides: [], stayOverrides: []
    )
}
