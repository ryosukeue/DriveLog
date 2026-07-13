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

    @Test("treats the 30 second and 10 meter boundaries as duplicates")
    func duplicateBoundaries() {
        let first = makeLocation(latitude: 0, longitude: 0, accuracy: 10, seconds: 0)
        let second = makeLocation(
            latitude: 0,
            longitude: longitude(atDistanceMeters: 10),
            accuracy: 10,
            seconds: 30
        )

        let result = sanitizer.sanitize([second, first])

        #expect(result.accepted == [second])
        #expect(result.rejected == [RejectedLocation(location: first, reason: .duplicate)])
    }

    @Test("keeps points when either duplicate condition is outside its boundary")
    func outsideDuplicateBoundaries() {
        let origin = makeLocation(latitude: 0, longitude: 0, seconds: 0)
        let tooFar = makeLocation(
            latitude: 0,
            longitude: longitude(atDistanceMeters: 10.01),
            seconds: 30
        )
        let tooLate = makeLocation(latitude: 0, longitude: 0, seconds: 31)

        #expect(sanitizer.sanitize([origin, tooFar]).accepted == [origin, tooFar])
        #expect(sanitizer.sanitize([origin, tooLate]).accepted == [origin, tooLate])
    }

    @Test("prefers better horizontal accuracy regardless of chronological side")
    func accuracyPriority() {
        let earlierBetter = makeLocation(accuracy: 5, seconds: 0)
        let laterWorse = makeLocation(accuracy: 20, seconds: 10)
        let earlierWorse = makeLocation(longitude: 140, accuracy: 20, seconds: 20)
        let laterBetter = makeLocation(longitude: 140, accuracy: 5, seconds: 30)

        let firstResult = sanitizer.sanitize([laterWorse, earlierBetter])
        let secondResult = sanitizer.sanitize([earlierWorse, laterBetter])

        #expect(firstResult.accepted == [earlierBetter])
        #expect(firstResult.rejected.map(\.location) == [laterWorse])
        #expect(secondResult.accepted == [laterBetter])
        #expect(secondResult.rejected.map(\.location) == [earlierWorse])
    }

    @Test("uses newer timestamp then earlier saved time as tie breakers")
    func duplicateTieBreakers() {
        let older = makeLocation(accuracy: 10, createdAt: now, seconds: 0)
        let newer = makeLocation(accuracy: 10, createdAt: now.addingTimeInterval(1), seconds: 10)
        let timestamp = now.addingTimeInterval(-500)
        let savedEarlier = makeLocation(
            latitude: 36,
            date: timestamp,
            accuracy: 10,
            createdAt: now.addingTimeInterval(2)
        )
        let savedLater = makeLocation(
            latitude: 36,
            date: timestamp,
            accuracy: 10,
            createdAt: now.addingTimeInterval(3)
        )

        #expect(sanitizer.sanitize([newer, older]).accepted == [newer])
        #expect(sanitizer.sanitize([savedLater, savedEarlier]).accepted == [savedEarlier])
    }

    @Test("uses injected duplicate thresholds")
    func injectedThresholds() {
        let rules = LocationRules(
            futureTimestampTolerance: 86400,
            duplicateTimeInterval: 5,
            duplicateDistance: 2,
            maximumHorizontalAccuracy: 500,
            maximumPlausibleSpeed: 250 / 3.6
        )
        let customSanitizer = LocationSanitizer(rules: rules, clock: FixedClock(now: now))
        let first = makeLocation(latitude: 0, longitude: 0, seconds: 0)
        let second = makeLocation(
            latitude: 0,
            longitude: longitude(atDistanceMeters: 2),
            seconds: 5
        )

        #expect(customSanitizer.sanitize([first, second]).accepted == [second])
    }

    @Test("keeps all rejection reasons in deterministic chronological order")
    func rejectionOrder() {
        let duplicate = makeLocation(accuracy: 20, seconds: 0)
        let invalid = makeLocation(latitude: .nan, seconds: 5)
        let preferred = makeLocation(accuracy: 5, seconds: 10)

        let result = sanitizer.sanitize([preferred, invalid, duplicate])

        #expect(result.rejected.map(\.reason) == [.duplicate, .invalidCoordinate])
        #expect(result.rejected[0].location == duplicate)
        #expect(result.rejected[1].location.timestamp == invalid.timestamp)
    }

    @Test("accepts 500 meter accuracy and rejects values above it")
    func poorAccuracyBoundary() {
        let boundary = makeLocation(accuracy: 500, seconds: 0)
        let overBoundary = makeLocation(longitude: 140, accuracy: 500.001, seconds: 1)

        let result = sanitizer.sanitize([overBoundary, boundary])

        #expect(result.accepted == [boundary])
        #expect(result.rejected == [
            RejectedLocation(location: overBoundary, reason: .poorAccuracy)
        ])
    }

    @Test("uses the injected maximum horizontal accuracy")
    func injectedAccuracyThreshold() {
        let rules = LocationRules(
            futureTimestampTolerance: 86400,
            duplicateTimeInterval: 30,
            duplicateDistance: 10,
            maximumHorizontalAccuracy: 100,
            maximumPlausibleSpeed: 250 / 3.6
        )
        let customSanitizer = LocationSanitizer(rules: rules, clock: FixedClock(now: now))
        let boundary = makeLocation(accuracy: 100, seconds: 0)
        let rejected = makeLocation(longitude: 140, accuracy: 100.1, seconds: 1)

        let result = customSanitizer.sanitize([boundary, rejected])

        #expect(result.accepted == [boundary])
        #expect(result.rejected.map(\.reason) == [.poorAccuracy])
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

    private func longitude(atDistanceMeters distance: Double) -> Double {
        distance / 6_371_000 * 180 / .pi
    }
}

private struct FixedClock: Clock {
    let now: Date
}
