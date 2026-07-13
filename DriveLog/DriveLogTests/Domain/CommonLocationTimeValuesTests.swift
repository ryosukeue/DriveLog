@testable import DriveLog
import Foundation
import Testing

@Suite("Common location and time values")
struct CommonLocationTimeValuesTests {
    @Test("Route coordinate preserves values and equality")
    func routeCoordinatePreservesValuesAndEquality() {
        let coordinate = RouteCoordinate(latitude: 35.0, longitude: 139.0)

        #expect(coordinate.latitude == 35.0)
        #expect(coordinate.longitude == 139.0)
        #expect(coordinate == RouteCoordinate(latitude: 35.0, longitude: 139.0))
        #expect(coordinate != RouteCoordinate(latitude: 35.1, longitude: 139.0))
        requireSendable(coordinate)
    }

    @Test("Location event preserves all values and optional speed")
    func locationEventPreservesAllValuesAndOptionalSpeed() {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let event = LocationEventData(
            latitude: 35.0,
            longitude: 139.0,
            timestamp: timestamp,
            horizontalAccuracy: 12.5,
            speedMetersPerSecond: nil,
            createdAt: timestamp,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2023-11-15"
        )

        #expect(event.speedMetersPerSecond == nil)
        #expect(event == locationEvent(timestamp: timestamp))
        #expect(event != locationEvent(timestamp: timestamp.addingTimeInterval(1)))
        requireSendable(event)
    }

    @Test("Motion event preserves multiple source flags and confidence")
    func motionEventPreservesMultipleSourceFlagsAndConfidence() {
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let event = MotionEventData(
            startDate: startDate,
            endDate: nil,
            isAutomotive: true,
            isWalking: true,
            isRunning: false,
            isCycling: false,
            isStationary: false,
            isUnknown: false,
            confidence: .medium,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2023-11-15"
        )

        #expect(event.isAutomotive)
        #expect(event.isWalking)
        #expect(event.endDate == nil)
        #expect(event.confidence == .medium)
        #expect(event == motionEvent(confidence: .medium))
        #expect(event != motionEvent(confidence: .high))
        requireSendable(event)
        requireSendable(MotionConfidence.low)
    }

    @Test("Visit event preserves incomplete dates")
    func visitEventPreservesIncompleteDates() {
        let arrivalDate = Date(timeIntervalSince1970: 1_700_000_000)
        let event = VisitEventData(
            latitude: 35.0,
            longitude: 139.0,
            arrivalDate: arrivalDate,
            departureDate: nil,
            horizontalAccuracy: 20,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2023-11-15"
        )

        #expect(event.arrivalDate == arrivalDate)
        #expect(event.departureDate == nil)
        #expect(event == visitEvent(departureDate: nil))
        #expect(event != visitEvent(departureDate: arrivalDate.addingTimeInterval(300)))
        requireSendable(event)
    }

    private func locationEvent(timestamp: Date) -> LocationEventData {
        LocationEventData(
            latitude: 35.0,
            longitude: 139.0,
            timestamp: timestamp,
            horizontalAccuracy: 12.5,
            speedMetersPerSecond: nil,
            createdAt: timestamp,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2023-11-15"
        )
    }

    private func motionEvent(confidence: MotionConfidence) -> MotionEventData {
        MotionEventData(
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: nil,
            isAutomotive: true,
            isWalking: true,
            isRunning: false,
            isCycling: false,
            isStationary: false,
            isUnknown: false,
            confidence: confidence,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2023-11-15"
        )
    }

    private func visitEvent(departureDate: Date?) -> VisitEventData {
        VisitEventData(
            latitude: 35.0,
            longitude: 139.0,
            arrivalDate: Date(timeIntervalSince1970: 1_700_000_000),
            departureDate: departureDate,
            horizontalAccuracy: 20,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2023-11-15"
        )
    }

    private func requireSendable(_: some Sendable) {}
}
