@testable import DriveLog
import Foundation
import Testing

struct ClockTimeZoneTests {
    @Test func fakeClockReturnsInjectedDate() {
        let expected = Date(timeIntervalSince1970: 1_700_000_000)

        #expect(FakeClock(now: expected).now == expected)
    }

    @Test func fakeClockCanBeReplacedWithDifferentFixedValue() {
        let first = FakeClock(now: Date(timeIntervalSince1970: 1_700_000_000))
        let second = FakeClock(now: Date(timeIntervalSince1970: 1_800_000_000))

        #expect(first.now != second.now)
    }

    @Test func fakeTimeZoneProviderReturnsInjectedTimeZone() throws {
        let expected = try #require(TimeZone(identifier: "Asia/Tokyo"))

        #expect(FakeTimeZoneProvider(current: expected).current == expected)
    }

    @Test func fakeTimeZoneProviderCanBeReplacedWithDifferentFixedValue() throws {
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let taipei = try #require(TimeZone(identifier: "Asia/Taipei"))
        let first = FakeTimeZoneProvider(current: tokyo)
        let second = FakeTimeZoneProvider(current: taipei)

        #expect(first.current != second.current)
    }

    @Test func systemClockReturnsDateWithinCallInterval() {
        let before = Date()
        let actual = SystemClock().now
        let after = Date()

        #expect(actual >= before)
        #expect(actual <= after)
    }

    @Test func systemTimeZoneProviderReturnsCurrentTimeZone() {
        #expect(SystemTimeZoneProvider().current == TimeZone.current)
    }
}

private struct FakeClock: Clock {
    let now: Date
}

private struct FakeTimeZoneProvider: TimeZoneProviding {
    let current: TimeZone
}
