@testable import DriveLog
import Foundation
import Testing

@Suite("Stable ID generator")
struct StableIDGeneratorTests {
    private let generator = SHA256StableIDGenerator()

    @Test("Same movement input is deterministic and SHA-256 formatted")
    func movementIDIsDeterministic() {
        let first = generator.movementSegmentID(
            localDateKey: "2026-07-13", startDate: date(10), endDate: date(610)
        )
        let second = generator.movementSegmentID(
            localDateKey: "2026-07-13", startDate: date(10), endDate: date(610)
        )

        #expect(first == second)
        #expect(first.count == 64)
        #expect(first.allSatisfy { $0.isHexDigit && !$0.isUppercase })
    }

    @Test("Movement dates use independent nearest-minute rounding")
    func movementDatesRoundToMinutes() {
        let baseline = generator.movementSegmentID(
            localDateKey: "2026-07-13", startDate: date(10), endDate: date(610)
        )
        let sameRoundedMinutes = generator.movementSegmentID(
            localDateKey: "2026-07-13", startDate: date(20), endDate: date(620)
        )
        let differentStart = generator.movementSegmentID(
            localDateKey: "2026-07-13", startDate: date(40), endDate: date(620)
        )
        let differentEnd = generator.movementSegmentID(
            localDateKey: "2026-07-13", startDate: date(20), endDate: date(640)
        )

        #expect(baseline == sameRoundedMinutes)
        #expect(baseline != differentStart)
        #expect(baseline != differentEnd)
    }

    @Test("Movement local date key changes the seed")
    func localDateKeyChangesMovementID() {
        let first = generator.movementSegmentID(
            localDateKey: "2026-07-13", startDate: date(0), endDate: date(600)
        )
        let second = generator.movementSegmentID(
            localDateKey: "2026-07-14", startDate: date(0), endDate: date(600)
        )

        #expect(first != second)
    }

    @Test("Stay coordinates round to four decimal places")
    func stayCoordinatesRoundToFourPlaces() {
        let baseline = stayID(latitude: 35.123_441, longitude: 139.123_441)
        let withinRange = stayID(latitude: 35.123_449, longitude: 139.123_449)
        let outsideLatitude = stayID(latitude: 35.123_461, longitude: 139.123_449)
        let outsideLongitude = stayID(latitude: 35.123_449, longitude: 139.123_461)

        #expect(baseline == withinRange)
        #expect(baseline != outsideLatitude)
        #expect(baseline != outsideLongitude)
    }

    @Test("Positive and negative zero coordinates produce the same stay ID")
    func normalizesNegativeZero() {
        #expect(stayID(latitude: 0, longitude: 0) == stayID(latitude: -0.0, longitude: -0.0))
    }

    private func stayID(latitude: Double, longitude: Double) -> String {
        generator.staySegmentID(
            localDateKey: "2026-07-13", arrivalDate: date(10), departureDate: date(610),
            latitude: latitude, longitude: longitude
        )
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 1_700_000_040 + seconds)
    }
}
