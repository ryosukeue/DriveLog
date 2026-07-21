import CoreLocation
@testable import DriveLog
import Foundation
import Testing

@Suite("Core Location provider")
@MainActor
struct CoreLocationProviderTests {
    @Test("converts CLLocation with recorded time context")
    func conversion() throws {
        let now = Date(timeIntervalSince1970: 1_704_067_500)
        let timestamp = Date(timeIntervalSince1970: 1_704_067_200)
        let provider = makeProvider(now: now)
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35, longitude: 139),
            altitude: 20, horizontalAccuracy: 12, verticalAccuracy: 5,
            course: 90, speed: 8, timestamp: timestamp
        )

        let event = try #require(provider.convert(location))

        #expect(event.latitude == 35)
        #expect(event.longitude == 139)
        #expect(event.timestamp == timestamp)
        #expect(event.horizontalAccuracy == 12)
        #expect(event.speedMetersPerSecond == 8)
        #expect(event.createdAt == now)
        #expect(event.timeZoneIdentifier == "Asia/Tokyo")
        #expect(event.utcOffsetSeconds == 32400)
        #expect(event.localDateKey == "2024-01-01")
    }

    @Test("rejects invalid accuracy and future timestamps and normalizes invalid speed")
    func validation() throws {
        let now = Date(timeIntervalSince1970: 1_704_067_200)
        let provider = makeProvider(now: now)
        #expect(provider.convert(location(now: now, accuracy: -1)) == nil)
        #expect(
            provider.convert(location(now: now.addingTimeInterval(301), accuracy: 10)) == nil
        )
        let event = try #require(
            provider.convert(location(now: now, accuracy: 10, speed: -1))
        )
        #expect(event.speedMetersPerSecond == nil)
    }

    @Test("delegate streams converted location and mapped error")
    func delegateEvents() async {
        let now = Date(timeIntervalSince1970: 1_704_067_200)
        let provider = makeProvider(now: now)
        var iterator = provider.events.makeAsyncIterator()

        provider.locationManager(
            CLLocationManager(),
            didUpdateLocations: [location(now: now, accuracy: 10)]
        )
        guard case let .location(event) = await iterator.next() else {
            Issue.record("Expected location event")
            return
        }
        #expect(event.timestamp == now)
        guard case let .acquisitionDiagnostic(diagnostic) = await iterator.next() else {
            Issue.record("Expected acquisition diagnostic")
            return
        }
        #expect(diagnostic == LocationAcquisitionDiagnostic(
            mode: .lowPower, receivedCount: 1, emittedCount: 1
        ))

        provider.locationManager(
            CLLocationManager(),
            didFailWithError: CLError(.network)
        )
        guard case .stateChanged(.failed(code: "location_error")) = await iterator.next() else {
            Issue.record("Expected failed state")
            return
        }
        guard case .error(.unknown(code: "location_network")) = await iterator.next() else {
            Issue.record("Expected mapped error")
            return
        }
    }

    @Test("candidate mode emits a separate movement stream")
    func candidateModeStreamsMovementEvidence() async throws {
        let now = Date(timeIntervalSince1970: 1_704_067_200)
        let provider = makeProvider(now: now)
        var eventIterator = provider.events.makeAsyncIterator()
        var locationIterator = provider.locationChanges.makeAsyncIterator()

        try await provider.setRecordingMode(.automotiveCandidate)

        provider.locationManager(
            CLLocationManager(),
            didUpdateLocations: [location(now: now, accuracy: 80, speed: 4)]
        )

        let evidence = try #require(await locationIterator.next())
        #expect(evidence.horizontalAccuracy == 80)
        #expect(evidence.speedMetersPerSecond == 4)
        var diagnosticValue: LocationAcquisitionDiagnostic?
        while let event = await eventIterator.next() {
            if case let .acquisitionDiagnostic(value) = event {
                diagnosticValue = value
                break
            }
        }
        let diagnostic = try #require(diagnosticValue)
        guard diagnostic.mode == .automotiveCandidate else {
            Issue.record("Expected candidate diagnostic")
            return
        }
        #expect(diagnostic.receivedCount == 1)
        #expect(diagnostic.emittedCount == 1)
    }

    @Test("fake tracks calls, state, location, and error")
    func fakeProvider() async throws {
        let fake = FakeLocationProvider()
        var iterator = fake.events.makeAsyncIterator()

        try await fake.startSignificantLocationMonitoring()
        guard case .stateChanged(.running) = await iterator.next() else {
            Issue.record("Expected running state")
            return
        }
        fake.send(.error(.monitoringUnavailable))
        guard case .error(.monitoringUnavailable) = await iterator.next() else {
            Issue.record("Expected fake error")
            return
        }
        await fake.stopSignificantLocationMonitoring()
        guard case .stateChanged(.stopped) = await iterator.next() else {
            Issue.record("Expected stopped state")
            return
        }
        #expect(await fake.monitoringState == .stopped)
        let counts = fake.callCounts()
        #expect(counts.start == 1)
        #expect(counts.stop == 1)
    }

    private func makeProvider(now: Date) -> CoreLocationProvider {
        CoreLocationProvider(
            clock: FixedLocationClock(now: now),
            localTimeContextProvider: FixedLocationTimeContextProvider()
        )
    }

    private func location(
        now: Date,
        accuracy: CLLocationAccuracy,
        speed: CLLocationSpeed = 0
    ) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35, longitude: 139),
            altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: 0,
            course: 0, speed: speed, timestamp: now
        )
    }
}

private struct FixedLocationClock: Clock {
    let now: Date
}

private struct FixedLocationTimeContextProvider: LocalTimeContextProviding {
    func makeContext(for _: Date) -> RecordedTimeContext {
        RecordedTimeContext(
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}
