import CoreMotion
@testable import DriveLog
import Foundation
import Testing

@Suite("Core Motion provider")
@MainActor
struct CoreMotionProviderTests {
    @Test("converts every flag, confidence, and recorded time context")
    func conversion() {
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        let provider = makeProvider()
        let event = provider.convert(
            snapshot(
                date: date, automotive: true, walking: true, running: true,
                cycling: true, stationary: true, unknown: true, confidence: .high
            )
        )

        #expect(event.startDate == date)
        #expect(event.endDate == nil)
        #expect(event.isAutomotive)
        #expect(event.isWalking)
        #expect(event.isRunning)
        #expect(event.isCycling)
        #expect(event.isStationary)
        #expect(event.isUnknown)
        #expect(event.confidence == .high)
        #expect(event.timeZoneIdentifier == "Asia/Tokyo")
        #expect(event.utcOffsetSeconds == 32400)
        #expect(event.localDateKey == "2024-01-01")
    }

    @Test("maps all confidence values")
    func confidence() {
        let provider = makeProvider()
        #expect(provider.convert(snapshot(confidence: .low)).confidence == .low)
        #expect(provider.convert(snapshot(confidence: .medium)).confidence == .medium)
        #expect(provider.convert(snapshot(confidence: .high)).confidence == .high)
    }

    @Test("streams callback error without OS details")
    func errorEvent() async {
        let provider = makeProvider()
        var iterator = provider.events.makeAsyncIterator()

        provider.sendCallbackError()

        guard case .stateChanged(.failed(code: "motion_error")) = await iterator.next() else {
            Issue.record("Expected failed state")
            return
        }
        guard case .error(.unknown(code: "core_motion")) = await iterator.next() else {
            Issue.record("Expected mapped error")
            return
        }
    }

    @Test("fake reproduces denial, calls, events, and stream completion")
    func fakeProvider() async {
        let fake = FakeMotionProvider()
        await fake.setStartError(.permissionDenied(.motion))
        await #expect(throws: DriveLogError.permissionDenied(.motion)) {
            try await fake.startMonitoring()
        }
        await fake.setStartError(nil)
        try? await fake.startMonitoring()
        await fake.stopMonitoring()
        let counts = await fake.callCounts()
        #expect(counts.start == 2)
        #expect(counts.stop == 1)

        let eventFake = FakeMotionProvider()
        var iterator = eventFake.events.makeAsyncIterator()
        await eventFake.send(.error(.monitoringUnavailable))
        guard case .error(.monitoringUnavailable) = await iterator.next() else {
            Issue.record("Expected fake error")
            return
        }
        await eventFake.finish()
        #expect(await iterator.next() == nil)
    }

    private func makeProvider() -> CoreMotionProvider {
        CoreMotionProvider(localTimeContextProvider: FixedMotionTimeContextProvider())
    }

    private func snapshot(
        date: Date = Date(timeIntervalSince1970: 1_704_067_200),
        automotive: Bool = false,
        walking: Bool = false,
        running: Bool = false,
        cycling: Bool = false,
        stationary: Bool = false,
        unknown: Bool = false,
        confidence: CMMotionActivityConfidence
    ) -> MotionActivitySnapshot {
        MotionActivitySnapshot(
            startDate: date, isAutomotive: automotive, isWalking: walking,
            isRunning: running, isCycling: cycling, isStationary: stationary,
            isUnknown: unknown, confidence: confidence
        )
    }
}

private struct FixedMotionTimeContextProvider: LocalTimeContextProviding {
    func makeContext(for _: Date) -> RecordedTimeContext {
        RecordedTimeContext(
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}
