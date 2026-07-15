import Foundation
import OSLog

nonisolated struct OSLogLogger: Logging {
    private let logger: Logger

    init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.ryosukeue.DriveLog",
        category: String = "application"
    ) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    func debug(_ event: LogEvent) {
        log(event, level: .debug)
    }

    func info(_ event: LogEvent) {
        log(event, level: .info)
    }

    func error(_ event: LogEvent) {
        log(event, level: .error)
    }

    private func log(_ event: LogEvent, level: OSLogType) {
        switch event {
        case .locationMonitoringStarted:
            logger.log(level: level, "Location monitoring started")
        case .locationMonitoringStopped:
            logger.log(level: level, "Location monitoring stopped")
        case let .locationEventSaved(localDateKey):
            logger.log(level: level, "Location event saved. localDateKey: \(localDateKey, privacy: .private)")
        case let .locationEventRejected(reasonCode):
            logger.log(level: level, "Location event rejected. reasonCode: \(reasonCode, privacy: .private)")
        case let .locationRecordingModeChanged(modeCode):
            logger.log(level: level, "Location recording mode changed. mode: \(modeCode, privacy: .private)")
        case let .locationAcquisitionCompleted(modeCode, receivedCount, emittedCount):
            logger.log(level: level, "Location acquisition mode: \(modeCode, privacy: .private)")
            logger.log(level: level, "Location received: \(receivedCount, privacy: .private)")
            logger.log(level: level, "Location emitted: \(emittedCount, privacy: .private)")
        case let .motionEventSaved(localDateKey):
            logger.log(level: level, "Motion event saved. localDateKey: \(localDateKey, privacy: .private)")
        case let .visitEventSaved(localDateKey):
            logger.log(level: level, "Visit event saved. localDateKey: \(localDateKey, privacy: .private)")
        default:
            logProcessingEvent(event, level: level)
        }
    }

    private func logProcessingEvent(_ event: LogEvent, level: OSLogType) {
        switch event {
        case let .dayProcessingStarted(localDateKey):
            logger.log(level: level, "Day processing started. localDateKey: \(localDateKey, privacy: .private)")
        case let .dayProcessingCompleted(localDateKey):
            logger.log(
                level: level,
                "Day processing completed. localDateKey: \(localDateKey, privacy: .private)"
            )
        case let .dayProcessingFailed(localDateKey, code):
            logger.log(
                level: level,
                "Day processing failed. dateKey: \(localDateKey, privacy: .private), code: \(code, privacy: .private)"
            )
        case let .mediaCacheRefreshed(localDateKey, count):
            logger.log(
                level: level,
                "Media cache refreshed. dateKey: \(localDateKey, privacy: .private), count: \(count, privacy: .private)"
            )
        case let .dayDeletionCompleted(localDateKey):
            logger.log(
                level: level,
                "Day deletion completed. localDateKey: \(localDateKey, privacy: .private)"
            )
        case let .dayDeletionFailed(localDateKey, code):
            logger.log(
                level: level,
                "Day deletion failed. dateKey: \(localDateKey, privacy: .private), code: \(code, privacy: .private)"
            )
        case .permissionStateChanged:
            logger.log(level: level, "Permission state changed")
        default:
            break
        }
    }
}
