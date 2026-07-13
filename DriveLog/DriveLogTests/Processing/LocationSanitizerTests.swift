@testable import DriveLog
import Foundation
import Testing

@Suite("Location sanitizer invalid values")
struct LocationSanitizerTests {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    @Test("accepts coordinate boundaries and rejects out of range coordinates")
    func coordinateRanges() {
        let locations = [
            makeLocation(latitude: -90, longitude: -180, seconds: 1),
            makeLocation(latitude: 90, longitude: 180, seconds: 2),
            makeLocation(latitude: -90.000_001, seconds: 3),
            makeLocation(latitude: 90.000_001, seconds: 4),
            makeLocation(longitude: -180.000_001, seconds: 5),
            makeLocation(longitude: 180.000_001, seconds: 6)
        ]

        let result = sanitizer.sanitize(locations)

        #expect(result.accepted == Array(locations.prefix(2)))
        #expect(result.rejected.map(\.reason) == Array(repeating: .invalidCoordinate, count: 4))
    }

    @Test("rejects non-finite coordinates")
    func nonFiniteCoordinates() {
        let locations = [
            makeLocation(latitude: .nan, seconds: 1),
            makeLocation(latitude: .infinity, seconds: 2),
            makeLocation(longitude: -.infinity, seconds: 3)
        ]

        let result = sanitizer.sanitize(locations)

        #expect(result.accepted.isEmpty)
        #expect(result.rejected.map(\.reason) == Array(repeating: .invalidCoordinate, count: 3))
    }

    @Test("accepts zero accuracy and rejects negative or non-finite accuracy")
    func invalidAccuracy() {
        let zero = makeLocation(accuracy: 0, seconds: 1)
        let invalid = [
            makeLocation(accuracy: -0.1, seconds: 2),
            makeLocation(accuracy: .nan, seconds: 3),
            makeLocation(accuracy: .infinity, seconds: 4)
        ]

        let result = sanitizer.sanitize([zero] + invalid)

        #expect(result.accepted == [zero])
        #expect(result.rejected.map(\.reason) == Array(repeating: .invalidAccuracy, count: 3))
    }

    @Test("rejects timestamps at or beyond 24 hours and non-finite dates")
    func futureTimestamps() {
        let within = makeLocation(date: now.addingTimeInterval(86399), seconds: 1)
        let boundary = makeLocation(date: now.addingTimeInterval(86400), seconds: 2)
        let beyond = makeLocation(date: now.addingTimeInterval(86401), seconds: 3)
        let invalid = makeLocation(
            date: Date(timeIntervalSinceReferenceDate: .nan), seconds: 4
        )

        let result = sanitizer.sanitize([boundary, invalid, within, beyond])

        #expect(result.accepted == [within])
        #expect(result.rejected.map(\.reason) == [
            .futureTimestamp, .futureTimestamp, .futureTimestamp
        ])
    }

    @Test("sorts by timestamp accuracy created date then original order")
    func deterministicSorting() {
        let timestamp = now.addingTimeInterval(-100)
        let laterCreatedAt = now.addingTimeInterval(-10)
        let earlierCreatedAt = now.addingTimeInterval(-20)
        let originalFirst = makeLocation(
            latitude: 10, date: timestamp, accuracy: 5, createdAt: earlierCreatedAt
        )
        let originalSecond = makeLocation(
            latitude: 20, date: timestamp, accuracy: 5, createdAt: earlierCreatedAt
        )
        let worseAccuracy = makeLocation(
            latitude: 30, date: timestamp, accuracy: 10, createdAt: earlierCreatedAt
        )
        let laterCreation = makeLocation(
            latitude: 40, date: timestamp, accuracy: 5, createdAt: laterCreatedAt
        )
        let earlierTimestamp = makeLocation(date: timestamp.addingTimeInterval(-1))

        let result = sanitizer.sanitize([
            worseAccuracy, originalFirst, laterCreation, earlierTimestamp, originalSecond
        ])

        #expect(result.accepted == [
            earlierTimestamp, originalFirst, originalSecond, laterCreation, worseAccuracy
        ])
    }

    @Test("handles empty single and all rejected inputs without mutating input")
    func edgeCases() {
        #expect(sanitizer.sanitize([]) == SanitizedLocations(accepted: [], rejected: []))
        let single = makeLocation()
        #expect(sanitizer.sanitize([single]).accepted == [single])

        let input = [makeLocation(latitude: .nan), makeLocation(accuracy: -1)]
        let original = input
        let result = sanitizer.sanitize(input)
        #expect(result.accepted.isEmpty)
        #expect(result.rejected.count == 2)
        #expect(input == original)
    }

    private var sanitizer: LocationSanitizer {
        LocationSanitizer(rules: ProcessingConfiguration.mvp.location, clock: FixedClock(now: now))
    }

    private func makeLocation(
        latitude: Double = 35,
        longitude: Double = 139,
        date: Date? = nil,
        accuracy: Double = 10,
        createdAt: Date? = nil,
        seconds: TimeInterval = 0
    ) -> LocationEventData {
        LocationEventData(
            latitude: latitude,
            longitude: longitude,
            timestamp: date ?? now.addingTimeInterval(-1000 + seconds),
            horizontalAccuracy: accuracy,
            speedMetersPerSecond: nil,
            createdAt: createdAt ?? now.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2033-05-18"
        )
    }
}

private struct FixedClock: Clock {
    let now: Date
}
