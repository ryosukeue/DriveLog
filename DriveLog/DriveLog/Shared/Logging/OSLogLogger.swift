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
        case let .locationRecordingModeChangeFailed(modeCode, reasonCode):
            logger.log(level: level, "Location recording mode change failed. mode: \(modeCode, privacy: .private)")
            logger.log(level: level, "Location mode change failure reason: \(reasonCode, privacy: .private)")
        case let .motionEventSaved(localDateKey):
            logger.log(level: level, "Motion event saved. localDateKey: \(localDateKey, privacy: .private)")
        case let .visitEventSaved(localDateKey):
            logger.log(level: level, "Visit event saved. localDateKey: \(localDateKey, privacy: .private)")
        default:
            if !logLocationDiagnosticEvent(event, level: level), !logVehicleEvent(event, level: level) {
                logOtherEvent(event, level: level)
            }
        }
    }

    private func logLocationDiagnosticEvent(_ event: LogEvent, level: OSLogType) -> Bool {
        guard case let .locationAcquisitionCompleted(modeCode, receivedCount, emittedCount) = event else {
            return false
        }
        logger.log(level: level, "Location acquisition mode: \(modeCode, privacy: .private)")
        logger.log(level: level, "Location received: \(receivedCount, privacy: .private)")
        logger.log(level: level, "Location emitted: \(emittedCount, privacy: .private)")
        return true
    }

    private func logVehicleEvent(_ event: LogEvent, level: OSLogType) -> Bool {
        switch event {
        case let .vehicleActivityObserved(activityCode):
            logger.log(level: level, "Vehicle activity observed: \(activityCode, privacy: .private)")
            return true
        case let .vehicleRecordingStateChanged(stateCode):
            logger.log(level: level, "Vehicle recording state changed: \(stateCode, privacy: .private)")
            return true
        default:
            return false
        }
    }

    private func logOtherEvent(_ event: LogEvent, level: OSLogType) {
        switch event {
        case let .powerStateObserved(stateCode):
            logger.log(level: level, "Power state observed. state: \(stateCode, privacy: .private)")
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
        case let .mediaPlacementDiagnosed(permissionCode, fetched, eligible, located):
            logger.log(level: level, "Media permission: \(permissionCode, privacy: .private)")
            logger.log(level: level, "Media fetched: \(fetched, privacy: .private)")
            logger.log(level: level, "Media eligible: \(eligible, privacy: .private)")
            logger.log(level: level, "Media located and placed: \(located, privacy: .private)")
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
