struct RecordedTimeContext: Sendable, Equatable {
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}
