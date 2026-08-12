@testable import DriveLog
import Foundation
import Testing

@Suite("Movement metrics calculator")
struct MovementMetricsCalculatorTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let calculator = MovementMetricsCalculator(rules: ProcessingConfiguration.mvp.segmentation)

    @Test("sums adjacent surface distances and calculates duration")
    func distanceAndDuration() {
        let result = calculator.calculate(locations: [
            location(distance: 0, seconds: 0),
            location(distance: 100, seconds: 60),
            location(distance: 250, seconds: 120)
        ])

        #expect(abs((result?.distanceMeters ?? 0) - 250) < 0.001)
        #expect(result?.durationSeconds == 120)
        #expect(abs((result?.estimatedAverageSpeedMetersPerSecond ?? 0) - 250 / 120) < 0.001)
    }

    @Test("includes duration and distance boundaries")
    func speedBoundaries() {
        let shortDuration = calculate(distance: 100, duration: 119.999)
        let durationBoundary = calculate(distance: 100, duration: 120)
        let shortDistance = calculate(distance: 99.999, duration: 120)

        #expect(shortDuration?.estimatedAverageSpeedMetersPerSecond == nil)
        #expect(durationBoundary?.estimatedAverageSpeedMetersPerSecond != nil)
        #expect(shortDistance?.estimatedAverageSpeedMetersPerSecond == nil)
    }

    @Test("handles empty one point zero duration and negative sequence")
    func invalidAndSparseInputs() {
        #expect(calculator.calculate(locations: []) == nil)

        let single = calculator.calculate(locations: [location(distance: 0, seconds: 0)])
        #expect(single?.distanceMeters == 0)
        #expect(single?.durationSeconds == 0)
        #expect(single?.estimatedAverageSpeedMetersPerSecond == nil)

        let zero = calculator.calculate(locations: [
            location(distance: 0, seconds: 0), location(distance: 100, seconds: 0)
        ])
        #expect(zero?.estimatedAverageSpeedMetersPerSecond == nil)

        let negative = calculator.calculate(locations: [
            location(distance: 0, seconds: 60), location(distance: 100, seconds: 0)
        ])
        #expect(negative == nil)
    }

    @Test("movement segmenter stores the calculated average speed")
    func segmenterIntegration() {
        let segmenter = MovementSegmenter(
            segmentationRules: ProcessingConfiguration.mvp.segmentation,
            stayRules: ProcessingConfiguration.mvp.stay
        )
        let result = segmenter.segment(
            locations: SanitizedLocations(accepted: [
                location(distance: 0, seconds: 0),
                location(distance: 240, seconds: 120)
            ], rejected: []),
            motions: [],
            visits: []
        )

        #expect(abs((result.segments.first?.estimatedAverageSpeedMetersPerSecond ?? 0) - 2) < 0.001)
    }

    private func calculate(distance: Double, duration: TimeInterval) -> MovementMetrics? {
        calculator.calculate(locations: [
            location(distance: 0, seconds: 0),
            location(distance: distance, seconds: duration)
        ])
    }

    private func location(distance: Double, seconds: TimeInterval) -> LocationEventData {
        LocationEventData(
            latitude: 0,
            longitude: distance / 6_371_000 * 180 / .pi,
            timestamp: baseDate.addingTimeInterval(seconds),
            horizontalAccuracy: 10,
            speedMetersPerSecond: nil,
            createdAt: baseDate.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}
