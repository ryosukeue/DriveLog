@testable import DriveLog
import Foundation
import Testing

@Suite("Local day boundary splitter")
struct LocalDayBoundarySplitterTests {
    private let splitter = LocalDayBoundarySplitter()
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("returns no buckets for empty input")
    func emptyInput() {
        #expect(splitter.split(rawEvents: .empty).isEmpty)
    }

    @Test("partitions every event type by its recorded local date key")
    func partitionsAllEventTypes() {
        let firstLocation = location(key: "2024-01-01", seconds: 0)
        let secondLocation = location(key: "2024-01-02", seconds: 1)
        let thirdLocation = location(key: "2024-01-01", seconds: 2)
        let motion = motion(key: "2024-01-02")
        let visit = visit(key: "2024-01-01")
        let classificationOverride = classificationOverride(key: "2024-01-02")
        let stayOverride = stayOverride(key: "2024-01-01")
        let input = RawDayEvents(
            locations: [firstLocation, secondLocation, thirdLocation],
            motions: [motion],
            visits: [visit],
            classificationOverrides: [classificationOverride],
            stayOverrides: [stayOverride]
        )

        let result = splitter.split(rawEvents: input)

        #expect(Set(result.keys) == ["2024-01-01", "2024-01-02"])
        #expect(result["2024-01-01"] == RawDayEvents(
            locations: [firstLocation, thirdLocation],
            motions: [],
            visits: [visit],
            classificationOverrides: [],
            stayOverrides: [stayOverride]
        ))
        #expect(result["2024-01-02"] == RawDayEvents(
            locations: [secondLocation],
            motions: [motion],
            visits: [],
            classificationOverrides: [classificationOverride],
            stayOverrides: []
        ))
    }

    @Test("uses recorded keys even when timestamps cross UTC day boundaries")
    func recordedKeyWins() {
        let utcNewYear = Date(timeIntervalSince1970: 1_704_067_200)
        let location = location(key: "2023-12-31", date: utcNewYear)
        let motion = motion(key: "2024-01-02", startDate: utcNewYear)
        let visit = visit(
            key: "2023-12-31",
            arrivalDate: utcNewYear.addingTimeInterval(-3600),
            departureDate: utcNewYear.addingTimeInterval(3600)
        )
        let input = RawDayEvents(
            locations: [location],
            motions: [motion],
            visits: [visit],
            classificationOverrides: [],
            stayOverrides: []
        )

        let result = splitter.split(rawEvents: input)

        #expect(result["2023-12-31"]?.locations == [location])
        #expect(result["2023-12-31"]?.visits == [visit])
        #expect(result["2024-01-02"]?.motions == [motion])
        #expect(result.values.reduce(0) { $0 + $1.visits.count } == 1)
        #expect(result.values.reduce(0) { $0 + $1.motions.count } == 1)
    }

    private func location(
        key: String,
        date: Date? = nil,
        seconds: TimeInterval = 0
    ) -> LocationEventData {
        LocationEventData(
            latitude: 35,
            longitude: 139,
            timestamp: date ?? baseDate.addingTimeInterval(seconds),
            horizontalAccuracy: 10,
            speedMetersPerSecond: nil,
            createdAt: baseDate.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: key
        )
    }

    private func motion(key: String, startDate: Date? = nil) -> MotionEventData {
        MotionEventData(
            startDate: startDate ?? baseDate,
            endDate: (startDate ?? baseDate).addingTimeInterval(7200),
            isAutomotive: true,
            isWalking: false,
            isRunning: false,
            isCycling: false,
            isStationary: false,
            isUnknown: false,
            confidence: .high,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: key
        )
    }

    private func visit(
        key: String,
        arrivalDate: Date? = nil,
        departureDate: Date? = nil
    ) -> VisitEventData {
        VisitEventData(
            latitude: 35,
            longitude: 139,
            arrivalDate: arrivalDate ?? baseDate,
            departureDate: departureDate ?? baseDate.addingTimeInterval(7200),
            horizontalAccuracy: 10,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: key
        )
    }

    private func classificationOverride(key: String) -> ClassificationOverrideData {
        ClassificationOverrideData(
            overrideKey: "classification",
            targetStableID: "movement",
            localDateKey: key,
            originalStartDate: baseDate,
            originalEndDate: baseDate.addingTimeInterval(60),
            userClassification: .train,
            createdAt: baseDate,
            updatedAt: baseDate
        )
    }

    private func stayOverride(key: String) -> StayOverrideData {
        StayOverrideData(
            overrideKey: "stay",
            targetStableID: "stay-segment",
            localDateKey: key,
            originalArrivalDate: baseDate,
            originalDepartureDate: baseDate.addingTimeInterval(60),
            originalCoordinate: RouteCoordinate(latitude: 35, longitude: 139),
            action: .confirm,
            createdAt: baseDate,
            updatedAt: baseDate
        )
    }
}
