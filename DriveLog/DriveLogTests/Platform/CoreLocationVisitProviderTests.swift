import CoreLocation
@testable import DriveLog
import Foundation
import Testing

@Suite("Core Location visit provider")
@MainActor
struct CoreLocationVisitProviderTests {
    @Test("converts arrival-only and departed visits")
    func conversion() throws {
        let provider = makeProvider()
        let arrival = Date(timeIntervalSince1970: 1_704_067_200)
        let arrivalOnly = try #require(
            provider.convert(snapshot(arrival: arrival, departure: .distantFuture))
        )
        #expect(arrivalOnly.arrivalDate == arrival)
        #expect(arrivalOnly.departureDate == nil)
        #expect(arrivalOnly.latitude == 35)
        #expect(arrivalOnly.longitude == 139)
        #expect(arrivalOnly.horizontalAccuracy == 25)

        let departure = arrival.addingTimeInterval(1800)
        let departed = try #require(
            provider.convert(snapshot(arrival: arrival, departure: departure))
        )
        #expect(departed.departureDate == departure)
    }

    @Test("normalizes unknown arrival and uses available date for time context")
    func sentinelAndTimeContext() throws {
        let provider = makeProvider()
        let departure = Date(timeIntervalSince1970: 1_704_067_200)

        let event = try #require(
            provider.convert(snapshot(arrival: .distantPast, departure: departure))
        )

        #expect(event.arrivalDate == nil)
        #expect(event.departureDate == departure)
        #expect(event.timeZoneIdentifier == "Asia/Tokyo")
        #expect(event.utcOffsetSeconds == 32400)
        #expect(event.localDateKey == "2024-01-01")
    }

    @Test("streams converted visits and mapped errors")
    func stream() async {
        let provider = makeProvider()
        var iterator = provider.events.makeAsyncIterator()
        provider.send(snapshot())
        guard case let .visit(event) = await iterator.next() else {
            Issue.record("Expected visit")
            return
        }
        #expect(event.departureDate == nil)

        provider.locationManager(CLLocationManager(), didFailWithError: CLError(.network))
        guard case .stateChanged(.failed(code: "visit_error")) = await iterator.next() else {
            Issue.record("Expected failed state")
            return
        }
        guard case .error(.unknown(code: "visit_network")) = await iterator.next() else {
            Issue.record("Expected mapped error")
            return
        }
    }

    @Test("fake can remain silent and then send arrival and update")
    func fakeProvider() async throws {
        let fake = FakeVisitProvider()
        try await fake.startMonitoring()
        #expect(await fake.monitoringState == .running)
        let arrival = visit(departure: nil)
        let update = visit(departure: Date(timeIntervalSince1970: 1_704_069_000))
        var iterator = fake.events.makeAsyncIterator()
        guard case .stateChanged(.running) = await iterator.next() else {
            Issue.record("Expected running state")
            return
        }
        fake.send(.visit(arrival))
        fake.send(.visit(update))
        guard case let .visit(first) = await iterator.next() else {
            Issue.record("Expected arrival")
            return
        }
        guard case let .visit(second) = await iterator.next() else {
            Issue.record("Expected update")
            return
        }
        #expect(first.departureDate == nil)
        #expect(second.departureDate != nil)
        await fake.stopMonitoring()
        let counts = fake.callCounts()
        #expect(counts.start == 1)
        #expect(counts.stop == 1)
    }

    private func makeProvider() -> CoreLocationVisitProvider {
        CoreLocationVisitProvider(
            clock: FixedVisitProviderClock(
                now: Date(timeIntervalSince1970: 1_704_067_200)
            ),
            localTimeContextProvider: FixedVisitTimeContextProvider()
        )
    }

    private func snapshot(
        arrival: Date = Date(timeIntervalSince1970: 1_704_067_200),
        departure: Date = .distantFuture
    ) -> VisitSnapshot {
        VisitSnapshot(
            coordinate: CLLocationCoordinate2D(latitude: 35, longitude: 139),
            horizontalAccuracy: 25, arrivalDate: arrival, departureDate: departure
        )
    }

    private func visit(departure: Date?) -> VisitEventData {
        VisitEventData(
            latitude: 35, longitude: 139,
            arrivalDate: Date(timeIntervalSince1970: 1_704_067_200),
            departureDate: departure, horizontalAccuracy: 25,
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}

private struct FixedVisitProviderClock: Clock {
    let now: Date
}

private struct FixedVisitTimeContextProvider: LocalTimeContextProviding {
    func makeContext(for _: Date) -> RecordedTimeContext {
        RecordedTimeContext(
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}
