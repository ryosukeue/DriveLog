@testable import DriveLog
import os
import Testing

struct LoggingTests {
    // swiftlint:disable:next function_body_length
    @Test func allLogEventCasesSupportEquality() {
        let equalPairs: [(LogEvent, LogEvent)] = [
            (.locationMonitoringStarted, .locationMonitoringStarted),
            (.locationMonitoringStopped, .locationMonitoringStopped),
            (
                .locationEventSaved(localDateKey: "2026-01-01"),
                .locationEventSaved(localDateKey: "2026-01-01")
            ),
            (
                .locationEventRejected(reasonCode: "TEST_REASON_A"),
                .locationEventRejected(reasonCode: "TEST_REASON_A")
            ),
            (
                .motionEventSaved(localDateKey: "2026-01-01"),
                .motionEventSaved(localDateKey: "2026-01-01")
            ),
            (
                .visitEventSaved(localDateKey: "2026-01-01"),
                .visitEventSaved(localDateKey: "2026-01-01")
            ),
            (
                .dayProcessingStarted(localDateKey: "2026-01-01"),
                .dayProcessingStarted(localDateKey: "2026-01-01")
            ),
            (
                .dayProcessingCompleted(localDateKey: "2026-01-01"),
                .dayProcessingCompleted(localDateKey: "2026-01-01")
            ),
            (
                .dayProcessingFailed(localDateKey: "2026-01-01", code: "TEST_CODE_A"),
                .dayProcessingFailed(localDateKey: "2026-01-01", code: "TEST_CODE_A")
            ),
            (
                .mediaCacheRefreshed(localDateKey: "2026-01-01", count: 1),
                .mediaCacheRefreshed(localDateKey: "2026-01-01", count: 1)
            ),
            (
                .mediaPlacementDiagnosed(
                    permissionCode: "limited", fetchedCount: 3,
                    eligibleCount: 2, locatedCount: 1
                ),
                .mediaPlacementDiagnosed(
                    permissionCode: "limited", fetchedCount: 3,
                    eligibleCount: 2, locatedCount: 1
                )
            ),
            (
                .dayDeletionCompleted(localDateKey: "2026-01-01"),
                .dayDeletionCompleted(localDateKey: "2026-01-01")
            ),
            (
                .dayDeletionFailed(localDateKey: "2026-01-01", code: "TEST_CODE_A"),
                .dayDeletionFailed(localDateKey: "2026-01-01", code: "TEST_CODE_A")
            ),
            (.permissionStateChanged, .permissionStateChanged),
            (
                .powerStateObserved(stateCode: "charging"),
                .powerStateObserved(stateCode: "charging")
            ),
            (
                .locationRecordingModeChanged(modeCode: "lowPower"),
                .locationRecordingModeChanged(modeCode: "lowPower")
            ),
            (
                .locationRecordingModeChangeFailed(
                    modeCode: "chargingHighAccuracy", reasonCode: "permission_denied"
                ),
                .locationRecordingModeChangeFailed(
                    modeCode: "chargingHighAccuracy", reasonCode: "permission_denied"
                )
            ),
            (
                .locationAcquisitionCompleted(
                    modeCode: "lowPower", receivedCount: 2, emittedCount: 1
                ),
                .locationAcquisitionCompleted(
                    modeCode: "lowPower", receivedCount: 2, emittedCount: 1
                )
            ),
            (
                .vehicleActivityObserved(activityCode: "automotive"),
                .vehicleActivityObserved(activityCode: "automotive")
            ),
            (
                .vehicleRecordingStateChanged(stateCode: "driving"),
                .vehicleRecordingStateChanged(stateCode: "driving")
            )
        ]

        for pair in equalPairs {
            #expect(pair.0 == pair.1)
        }
    }

    @Test func logEventsWithDifferentAssociatedValuesAreNotEqual() {
        #expect(
            LogEvent.locationEventSaved(localDateKey: "2026-01-01")
                != .locationEventSaved(localDateKey: "2026-01-02")
        )
        #expect(
            LogEvent.locationEventRejected(reasonCode: "TEST_REASON_A")
                != .locationEventRejected(reasonCode: "TEST_REASON_B")
        )
        #expect(
            LogEvent.powerStateObserved(stateCode: "charging")
                != .powerStateObserved(stateCode: "unplugged")
        )
        #expect(
            LogEvent.vehicleActivityObserved(activityCode: "automotive")
                != .vehicleActivityObserved(activityCode: "stationary")
        )
        #expect(
            LogEvent.vehicleRecordingStateChanged(stateCode: "driving")
                != .vehicleRecordingStateChanged(stateCode: "idle")
        )
        #expect(
            LogEvent.dayProcessingFailed(localDateKey: "2026-01-01", code: "TEST_CODE_A")
                != .dayProcessingFailed(localDateKey: "2026-01-02", code: "TEST_CODE_A")
        )
        #expect(
            LogEvent.dayProcessingFailed(localDateKey: "2026-01-01", code: "TEST_CODE_A")
                != .dayProcessingFailed(localDateKey: "2026-01-01", code: "TEST_CODE_B")
        )
        #expect(
            LogEvent.mediaCacheRefreshed(localDateKey: "2026-01-01", count: 1)
                != .mediaCacheRefreshed(localDateKey: "2026-01-01", count: 2)
        )
        #expect(
            LogEvent.mediaPlacementDiagnosed(
                permissionCode: "limited", fetchedCount: 3,
                eligibleCount: 2, locatedCount: 1
            ) != .mediaPlacementDiagnosed(
                permissionCode: "limited", fetchedCount: 3,
                eligibleCount: 2, locatedCount: 0
            )
        )
        #expect(
            LogEvent.dayDeletionFailed(localDateKey: "2026-01-01", code: "TEST_CODE_A")
                != .dayDeletionFailed(localDateKey: "2026-01-01", code: "TEST_CODE_B")
        )
    }

    @Test func differentLogEventCasesAreNotEqual() {
        #expect(LogEvent.locationMonitoringStarted != .locationMonitoringStopped)
        #expect(LogEvent.dayProcessingStarted(localDateKey: "2026-01-01") != .permissionStateChanged)
    }

    @Test func spyLoggerRecordsLevelsAndEventsInOrder() {
        let spy = SpyLogger()

        spy.debug(.locationMonitoringStarted)
        spy.info(.locationEventSaved(localDateKey: "2026-01-01"))
        spy.error(.dayProcessingFailed(localDateKey: "2026-01-01", code: "TEST_CODE_A"))

        #expect(
            spy.records == [
                LogRecord(level: .debug, event: .locationMonitoringStarted),
                LogRecord(level: .info, event: .locationEventSaved(localDateKey: "2026-01-01")),
                LogRecord(
                    level: .error,
                    event: .dayProcessingFailed(localDateKey: "2026-01-01", code: "TEST_CODE_A")
                )
            ]
        )
    }

    @Test func osLogLoggerAcceptsDefaultAndInjectedConfiguration() {
        OSLogLogger().debug(.permissionStateChanged)

        let logger = OSLogLogger(subsystem: "com.ryosukeue.DriveLogTests", category: "test")
        logger.info(.mediaCacheRefreshed(localDateKey: "2026-01-01", count: 1))
        logger.error(.locationEventRejected(reasonCode: "TEST_REASON_A"))
    }
}

private enum LogLevel: Sendable, Equatable {
    case debug
    case info
    case error
}

private struct LogRecord: Sendable, Equatable {
    let level: LogLevel
    let event: LogEvent
}

private final class SpyLogger: Logging {
    private let storage = OSAllocatedUnfairLock(initialState: [LogRecord]())

    var records: [LogRecord] {
        storage.withLock { $0 }
    }

    func debug(_ event: LogEvent) {
        record(level: .debug, event: event)
    }

    func info(_ event: LogEvent) {
        record(level: .info, event: event)
    }

    func error(_ event: LogEvent) {
        record(level: .error, event: event)
    }

    private func record(level: LogLevel, event: LogEvent) {
        storage.withLock {
            $0.append(LogRecord(level: level, event: event))
        }
    }
}
