@testable import DriveLog
import os

enum TestLogLevel: Sendable, Equatable {
    case debug
    case info
    case error
}

struct TestLogRecord: Sendable, Equatable {
    let level: TestLogLevel
    let event: LogEvent
}

final class SpyEventLogger: Logging {
    nonisolated let updates: AsyncStream<TestLogRecord>
    private let storage = OSAllocatedUnfairLock(initialState: [TestLogRecord]())
    private let continuation: AsyncStream<TestLogRecord>.Continuation

    init() {
        let stream = AsyncStream.makeStream(of: TestLogRecord.self)
        updates = stream.stream
        continuation = stream.continuation
    }

    var records: [TestLogRecord] {
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

    private func record(level: TestLogLevel, event: LogEvent) {
        let record = TestLogRecord(level: level, event: event)
        storage.withLock { $0.append(record) }
        continuation.yield(record)
    }
}
