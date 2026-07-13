@testable import DriveLog
import Foundation
import os
import Testing

struct LocalTimeContextProviderTests {
    @Test func tokyoContextUsesLocalDateAndOffset() throws {
        let provider = try makeProvider(timeZoneIdentifier: "Asia/Tokyo")
        let context = try provider.makeContext(for: date("2026-01-15T15:01:00Z"))

        #expect(context.timeZoneIdentifier == "Asia/Tokyo")
        #expect(context.utcOffsetSeconds == 32400)
        #expect(context.localDateKey == "2026-01-16")
    }

    @Test func taipeiContextUsesLocalDateAndOffset() throws {
        let provider = try makeProvider(timeZoneIdentifier: "Asia/Taipei")
        let context = try provider.makeContext(for: date("2026-07-15T01:00:00Z"))

        #expect(context.timeZoneIdentifier == "Asia/Taipei")
        #expect(context.utcOffsetSeconds == 28800)
        #expect(context.localDateKey == "2026-07-15")
    }

    @Test func localDateChangesAcrossLocalMidnight() throws {
        let provider = try makeProvider(timeZoneIdentifier: "Asia/Tokyo")

        let beforeMidnight = try provider.makeContext(for: date("2026-01-15T14:59:00Z"))
        let afterMidnight = try provider.makeContext(for: date("2026-01-15T15:01:00Z"))

        #expect(beforeMidnight.localDateKey == "2026-01-15")
        #expect(afterMidnight.localDateKey == "2026-01-16")
    }

    @Test func recordedContextDoesNotChangeWhenProviderTimeZoneChanges() throws {
        let timeZoneProvider = try MutableTimeZoneProvider(
            current: #require(TimeZone(identifier: "Asia/Taipei"))
        )
        let provider = DefaultLocalTimeContextProvider(timeZoneProvider: timeZoneProvider)
        let eventDate = try date("2026-07-15T15:30:00Z")
        let recorded = provider.makeContext(for: eventDate)

        try timeZoneProvider.setCurrent(#require(TimeZone(identifier: "Asia/Tokyo")))
        let current = provider.makeContext(for: eventDate)

        #expect(recorded.timeZoneIdentifier == "Asia/Taipei")
        #expect(recorded.localDateKey == "2026-07-15")
        #expect(current.timeZoneIdentifier == "Asia/Tokyo")
        #expect(current.localDateKey == "2026-07-16")
        #expect(recorded.localDateKey == "2026-07-15")
    }

    @Test func daylightSavingStartUsesOffsetAtEventDate() throws {
        let provider = try makeProvider(timeZoneIdentifier: "America/Los_Angeles")

        let before = try provider.makeContext(for: date("2026-03-08T09:59:00Z"))
        let after = try provider.makeContext(for: date("2026-03-08T10:01:00Z"))

        #expect(before.utcOffsetSeconds == -28800)
        #expect(after.utcOffsetSeconds == -25200)
        #expect(before.localDateKey == "2026-03-08")
        #expect(after.localDateKey == "2026-03-08")
    }

    @Test func daylightSavingEndUsesOffsetAtEventDate() throws {
        let provider = try makeProvider(timeZoneIdentifier: "America/Los_Angeles")

        let before = try provider.makeContext(for: date("2026-11-01T08:59:00Z"))
        let after = try provider.makeContext(for: date("2026-11-01T09:01:00Z"))

        #expect(before.utcOffsetSeconds == -25200)
        #expect(after.utcOffsetSeconds == -28800)
        #expect(before.localDateKey == "2026-11-01")
        #expect(after.localDateKey == "2026-11-01")
    }

    private func makeProvider(timeZoneIdentifier: String) throws -> DefaultLocalTimeContextProvider {
        let timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        return DefaultLocalTimeContextProvider(timeZoneProvider: FixedTimeZoneProvider(current: timeZone))
    }

    private func date(_ value: String) throws -> Date {
        try Date.ISO8601FormatStyle().parse(value)
    }
}

private struct FixedTimeZoneProvider: TimeZoneProviding {
    let current: TimeZone
}

private final class MutableTimeZoneProvider: TimeZoneProviding {
    private let storage: OSAllocatedUnfairLock<TimeZone>

    var current: TimeZone {
        storage.withLock { $0 }
    }

    init(current: TimeZone) {
        storage = OSAllocatedUnfairLock(initialState: current)
    }

    func setCurrent(_ timeZone: TimeZone) {
        storage.withLock {
            $0 = timeZone
        }
    }
}
