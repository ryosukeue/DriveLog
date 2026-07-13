@testable import DriveLog
import Foundation
import Testing

@Suite("Location sanitizer jump detection")
struct LocationSanitizerJumpTests {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    @Test("keeps speeds up to 250 kilometers per hour and rejects values above it")
    func plausibleSpeedBoundary() {
        let origin = makeLocation(distanceMeters: 0, seconds: 0)
        let below = makeLocation(distanceMeters: kilometersPerHour(249) * 60, seconds: 60)
        let boundary = makeLocation(distanceMeters: kilometersPerHour(250) * 60, seconds: 60)
        let above = makeLocation(distanceMeters: kilometersPerHour(250) * 60 + 0.1, seconds: 60)

        #expect(sanitizer.sanitize([origin, below]).accepted == [origin, below])
        #expect(sanitizer.sanitize([origin, boundary]).accepted == [origin, boundary])
        #expect(sanitizer.sanitize([origin, above]).rejected.map(\.reason) == [.implausibleJump])
    }

    @Test("removes an abnormal middle point when the surrounding route is plausible")
    func abnormalMiddlePoint() {
        let first = makeLocation(distanceMeters: 0, seconds: 0, accuracy: 10)
        let abnormal = makeLocation(distanceMeters: 100_000, seconds: 60, accuracy: 1)
        let last = makeLocation(distanceMeters: 1000, seconds: 120, accuracy: 10)

        let result = sanitizer.sanitize([last, abnormal, first])

        #expect(result.accepted == [first, last])
        #expect(result.rejected == [
            RejectedLocation(location: abnormal, reason: .implausibleJump)
        ])
    }

    @Test("removes an abnormal final point")
    func abnormalFinalPoint() {
        let first = makeLocation(distanceMeters: 0, seconds: 0, accuracy: 10)
        let middle = makeLocation(distanceMeters: 1000, seconds: 60, accuracy: 10)
        let abnormal = makeLocation(distanceMeters: 100_000, seconds: 120, accuracy: 50)

        let result = sanitizer.sanitize([first, middle, abnormal])

        #expect(result.accepted == [first, middle])
        #expect(result.rejected.map(\.location) == [abnormal])
    }

    @Test("falls back to accuracy and then the later point")
    func jumpFallbackPriority() {
        let lessAccurateEarlier = makeLocation(distanceMeters: 0, seconds: 0, accuracy: 100)
        let accurateLater = makeLocation(distanceMeters: 10000, seconds: 60, accuracy: 10)
        let equalEarlier = makeLocation(distanceMeters: 20000, seconds: 120, accuracy: 10)
        let equalLater = makeLocation(distanceMeters: 30000, seconds: 180, accuracy: 10)

        let accuracyResult = sanitizer.sanitize([lessAccurateEarlier, accurateLater])
        let equalResult = sanitizer.sanitize([equalEarlier, equalLater])

        #expect(accuracyResult.accepted == [accurateLater])
        #expect(accuracyResult.rejected.map(\.location) == [lessAccurateEarlier])
        #expect(equalResult.accepted == [equalEarlier])
        #expect(equalResult.rejected.map(\.location) == [equalLater])
    }

    @Test("marks distinct coordinates at the same time as an invalid sequence")
    func invalidTimeSequence() {
        let first = makeLocation(distanceMeters: 0, seconds: 0)
        let second = makeLocation(distanceMeters: 1000, seconds: 0)

        let result = sanitizer.sanitize([first, second])

        #expect(result.accepted == [first])
        #expect(result.rejected == [
            RejectedLocation(location: second, reason: .invalidSequence)
        ])
    }

    @Test("handles insufficient points and an injected speed threshold")
    func speedEdgeCases() {
        let single = makeLocation(distanceMeters: 0, seconds: 0)
        #expect(sanitizer.sanitize([single]).accepted == [single])

        let rules = LocationRules(
            futureTimestampTolerance: 86400,
            duplicateTimeInterval: 30,
            duplicateDistance: 10,
            maximumHorizontalAccuracy: 500,
            maximumPlausibleSpeed: 10
        )
        let customSanitizer = LocationSanitizer(rules: rules, clock: JumpFixedClock(now: now))
        let later = makeLocation(distanceMeters: 100, seconds: 5)

        #expect(customSanitizer.sanitize([single, later]).rejected.map(\.reason) == [
            .implausibleJump
        ])
    }

    private var sanitizer: LocationSanitizer {
        LocationSanitizer(
            rules: ProcessingConfiguration.mvp.location,
            clock: JumpFixedClock(now: now)
        )
    }

    private func makeLocation(
        distanceMeters: Double,
        seconds: TimeInterval,
        accuracy: Double = 10
    ) -> LocationEventData {
        LocationEventData(
            latitude: 0,
            longitude: distanceMeters / 6_371_000 * 180 / .pi,
            timestamp: now.addingTimeInterval(-1000 + seconds),
            horizontalAccuracy: accuracy,
            speedMetersPerSecond: nil,
            createdAt: now.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2033-05-18"
        )
    }

    private func kilometersPerHour(_ value: Double) -> Double {
        value / 3.6
    }
}

private struct JumpFixedClock: Clock {
    let now: Date
}
