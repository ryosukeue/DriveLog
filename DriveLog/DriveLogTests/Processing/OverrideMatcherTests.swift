@testable import DriveLog
import Foundation
import Testing

@Suite("Override matcher")
struct OverrideMatcherTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let matcher = OverrideMatcher(rules: ProcessingConfiguration.mvp.overrideMatching)

    @Test("prioritizes one exact movement stable ID")
    func exactMovementMatch() {
        let exact = movement(id: "old", start: 10000, end: 10100, day: "other-day")
        let approximate = movement(id: "new", start: 0, end: 3600)

        let result = matcher.matchClassificationOverride(classificationOverride(), to: [approximate, exact])

        #expect(result?.stableID == exact.stableID)
    }

    @Test("includes movement time tolerances and fifty percent overlap")
    func movementBoundaries() {
        let candidate = movement(id: "new", start: 900, end: 2700)

        #expect(
            matcher.matchClassificationOverride(classificationOverride(end: 1800), to: [candidate])?.stableID ==
                candidate.stableID
        )
    }

    @Test("rejects movement values outside each boundary and a different day")
    func movementOutsideBoundaries() {
        let values = [
            movement(id: "start", start: 900.001, end: 2700),
            movement(id: "end", start: 900, end: 2699.999),
            movement(id: "day", start: 900, end: 2700, day: "2024-01-02")
        ]

        for value in values {
            #expect(matcher.matchClassificationOverride(classificationOverride(), to: [value])?.stableID == nil)
        }
        let lowOverlap = movement(id: "overlap", start: 900, end: 2100)
        #expect(
            matcher.matchClassificationOverride(classificationOverride(end: 1200), to: [lowOverlap])?.stableID == nil
        )
    }

    @Test("accepts only one approximate movement candidate")
    func uniqueMovementCandidate() {
        let first = movement(id: "first", start: 10, end: 3590)
        let second = movement(id: "second", start: 20, end: 3580)

        #expect(matcher.matchClassificationOverride(classificationOverride(), to: [])?.stableID == nil)
        #expect(matcher.matchClassificationOverride(classificationOverride(), to: [first])?.stableID == first.stableID)
        #expect(matcher.matchClassificationOverride(classificationOverride(), to: [first, second])?.stableID == nil)
        let exactDuplicates = [
            movement(id: "old", start: 0, end: 3600),
            movement(id: "old", start: 0, end: 3600)
        ]
        #expect(matcher.matchClassificationOverride(classificationOverride(), to: exactDuplicates)?.stableID == nil)
    }

    @Test("prioritizes one exact stay stable ID")
    func exactStayMatch() {
        let exact = stay(id: "old-stay", arrival: 10000, departure: 11000, eastMeters: 1000, day: "other")
        let approximate = stay(id: "new", arrival: 0, departure: 3600, eastMeters: 0)

        #expect(matcher.matchStayOverride(stayOverride(), to: [approximate, exact]) == exact)
    }

    @Test("includes stay time and coordinate boundaries")
    func stayBoundaries() {
        let candidate = stay(id: "new", arrival: 900, departure: 4500, eastMeters: 300)

        #expect(matcher.matchStayOverride(stayOverride(), to: [candidate]) == candidate)
    }

    @Test("rejects stay values outside each boundary and a different day")
    func stayOutsideBoundaries() {
        let values = [
            stay(id: "arrival", arrival: 900.001, departure: 4500, eastMeters: 300),
            stay(id: "departure", arrival: 900, departure: 4500.001, eastMeters: 300),
            stay(id: "coordinate", arrival: 900, departure: 4500, eastMeters: 300.1),
            stay(id: "day", arrival: 900, departure: 4500, eastMeters: 300, day: "2024-01-02")
        ]

        for value in values {
            #expect(matcher.matchStayOverride(stayOverride(), to: [value]) == nil)
        }
    }

    @Test("accepts only one approximate stay candidate")
    func uniqueStayCandidate() {
        let first = stay(id: "first", arrival: 10, departure: 3590, eastMeters: 10)
        let second = stay(id: "second", arrival: 20, departure: 3580, eastMeters: 20)

        #expect(matcher.matchStayOverride(stayOverride(), to: []) == nil)
        #expect(matcher.matchStayOverride(stayOverride(), to: [first]) == first)
        #expect(matcher.matchStayOverride(stayOverride(), to: [first, second]) == nil)
        let exactDuplicates = [
            stay(id: "old-stay", arrival: 0, departure: 3600, eastMeters: 0),
            stay(id: "old-stay", arrival: 0, departure: 3600, eastMeters: 0)
        ]
        #expect(matcher.matchStayOverride(stayOverride(), to: exactDuplicates) == nil)
    }

    @Test("does not mutate override inputs")
    func overrideImmutability() {
        let classification = classificationOverride()
        let stay = stayOverride()
        let originalClassification = classification
        let originalStay = stay

        _ = matcher.matchClassificationOverride(classification, to: [movement(id: "new", start: 0, end: 3600)])
        _ = matcher.matchStayOverride(stay, to: [self.stay(id: "new", arrival: 0, departure: 3600, eastMeters: 0)])

        #expect(classification == originalClassification)
        #expect(stay == originalStay)
    }

    private func classificationOverride(end: TimeInterval = 3600) -> ClassificationOverrideData {
        ClassificationOverrideData(
            overrideKey: "classification",
            targetStableID: "old",
            localDateKey: "2024-01-01",
            originalStartDate: baseDate,
            originalEndDate: baseDate.addingTimeInterval(end),
            userClassification: .automotive,
            createdAt: baseDate,
            updatedAt: baseDate
        )
    }

    private func stayOverride() -> StayOverrideData {
        StayOverrideData(
            overrideKey: "stay",
            targetStableID: "old-stay",
            localDateKey: "2024-01-01",
            originalArrivalDate: baseDate,
            originalDepartureDate: baseDate.addingTimeInterval(3600),
            originalCoordinate: coordinate(eastMeters: 0),
            action: .confirm,
            createdAt: baseDate,
            updatedAt: baseDate
        )
    }

    private func movement(
        id: String,
        start: TimeInterval,
        end: TimeInterval,
        day: String = "2024-01-01"
    ) -> MovementSegmentData {
        MovementSegmentData(
            stableID: id,
            localDateKey: day,
            startDate: baseDate.addingTimeInterval(start),
            endDate: baseDate.addingTimeInterval(end),
            distanceMeters: 1000,
            durationSeconds: end - start,
            estimatedAverageSpeedMetersPerSecond: nil,
            automaticClassification: .other,
            classificationConfidence: .low,
            route: [],
            labelCoordinate: nil,
            sourceRawRevision: 1,
            generatedAt: baseDate
        )
    }

    private func stay(
        id: String,
        arrival: TimeInterval,
        departure: TimeInterval,
        eastMeters: Double,
        day: String = "2024-01-01"
    ) -> StaySegmentData {
        StaySegmentData(
            stableID: id,
            localDateKey: day,
            representativeCoordinate: coordinate(eastMeters: eastMeters),
            estimatedArrivalDate: baseDate.addingTimeInterval(arrival),
            estimatedDepartureDate: baseDate.addingTimeInterval(departure),
            durationSeconds: departure - arrival,
            confidence: .medium,
            source: .combined,
            isVisibleByAutomaticRule: true,
            sourceRawRevision: 1,
            generatedAt: baseDate
        )
    }

    private func coordinate(eastMeters: Double) -> RouteCoordinate {
        RouteCoordinate(latitude: 0, longitude: eastMeters / 6_371_000 * 180 / .pi)
    }
}
