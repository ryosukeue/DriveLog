@testable import DriveLog
import Foundation
import os
import Testing

@Suite("AppContainer")
@MainActor
struct AppContainerTests {
    @Test("Foundation dependencies can be injected")
    func foundationDependenciesCanBeInjected() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let context = RecordedTimeContext(
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2023-11-15"
        )
        let logger = ContainerSpyLogger()
        let hapticFeedback = ContainerSpyHapticFeedback()
        let container = AppContainer(
            logger: logger,
            clock: ContainerFixedClock(now: date),
            timeZoneProvider: ContainerFixedTimeZoneProvider(current: timeZone),
            localTimeContextProvider: ContainerFixedLocalTimeContextProvider(context: context),
            hapticFeedback: hapticFeedback
        )

        container.logger.info(.permissionStateChanged)

        #expect(logger.events == [.permissionStateChanged])
        #expect(container.clock.now == date)
        #expect(container.timeZoneProvider.current == timeZone)
        #expect(container.localTimeContextProvider.makeContext(for: date) == context)
        container.hapticFeedback.performLightSuccess()
        #expect(hapticFeedback.callCount == 1)
    }

    @Test("Production dependencies provide current values")
    func productionDependenciesProvideCurrentValues() {
        let container = AppContainer()
        let before = Date()
        let now = container.clock.now
        let after = Date()

        #expect((before ... after).contains(now))
        #expect(container.timeZoneProvider.current == TimeZone.current)

        let context = container.localTimeContextProvider.makeContext(for: now)
        #expect(context.timeZoneIdentifier == TimeZone.current.identifier)
    }
}

private struct ContainerFixedClock: Clock {
    let now: Date
}

private struct ContainerFixedTimeZoneProvider: TimeZoneProviding {
    let current: TimeZone
}

private struct ContainerFixedLocalTimeContextProvider: LocalTimeContextProviding {
    let context: RecordedTimeContext

    func makeContext(for _: Date) -> RecordedTimeContext {
        context
    }
}

private final class ContainerSpyLogger: Logging, @unchecked Sendable {
    private let storage = OSAllocatedUnfairLock(initialState: [LogEvent]())

    var events: [LogEvent] {
        storage.withLock { $0 }
    }

    func debug(_ event: LogEvent) {
        record(event)
    }

    func info(_ event: LogEvent) {
        record(event)
    }

    func error(_ event: LogEvent) {
        record(event)
    }

    private func record(_ event: LogEvent) {
        storage.withLock { events in
            events.append(event)
        }
    }
}

@MainActor
private final class ContainerSpyHapticFeedback: HapticFeedbackProviding {
    private(set) var callCount = 0

    func performLightSuccess() {
        callCount += 1
    }
}
