nonisolated enum LogEvent: Sendable, Equatable {
    case locationMonitoringStarted
    case locationMonitoringStopped
    case locationEventSaved(localDateKey: String)
    case locationEventRejected(reasonCode: String)
    case motionEventSaved(localDateKey: String)
    case visitEventSaved(localDateKey: String)
    case dayProcessingStarted(localDateKey: String)
    case dayProcessingCompleted(localDateKey: String)
    case dayProcessingFailed(localDateKey: String, code: String)
    case mediaCacheRefreshed(localDateKey: String, count: Int)
    case mediaPlacementDiagnosed(
        permissionCode: String,
        fetchedCount: Int,
        eligibleCount: Int,
        locatedCount: Int
    )
    case dayDeletionCompleted(localDateKey: String)
    case dayDeletionFailed(localDateKey: String, code: String)
    case permissionStateChanged
    case locationRecordingModeChanged(modeCode: String)
    case locationAcquisitionCompleted(modeCode: String, receivedCount: Int, emittedCount: Int)
}
