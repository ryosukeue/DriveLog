@testable import DriveLog
import Foundation
import Testing

@Suite("Movement segment data")
struct MovementSegmentDataTests {
    @Test("Classification enums expose only designed cases")
    func classificationCases() {
        let confidence: [ClassificationConfidence] = [.low, .medium, .high]
        let userClassifications: [UserMovementClassification] = [
            .automotive, .train, .bus, .walking, .other
        ]

        #expect(confidence[0] != confidence[1])
        #expect(userClassifications[0] != userClassifications[1])
        requireSendable(confidence)
        requireSendable(userClassifications)
    }

    @Test("Movement segment preserves route and V1 values")
    func movementSegmentPreservesValues() {
        let segment = makeSegment(distance: 2500)

        #expect(segment.route.count == 2)
        #expect(segment.labelCoordinate == RouteCoordinate(latitude: 35.005, longitude: 139.005))
        #expect(segment.estimatedAverageSpeedMetersPerSecond == nil)
        #expect(segment.automaticClassification == .automotiveLike)
        #expect(segment.classificationConfidence == .high)
        #expect(segment == makeSegment(distance: 2500))
        #expect(segment != makeSegment(distance: 2501))
        requireSendable(segment)
    }

    private func makeSegment(distance: Double) -> MovementSegmentData {
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        return MovementSegmentData(
            stableID: "stable-movement-id",
            localDateKey: "2023-11-15",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(600),
            distanceMeters: distance,
            durationSeconds: 600,
            estimatedAverageSpeedMetersPerSecond: nil,
            automaticClassification: .automotiveLike,
            classificationConfidence: .high,
            route: [
                RouteCoordinate(latitude: 35.0, longitude: 139.0),
                RouteCoordinate(latitude: 35.01, longitude: 139.01)
            ],
            labelCoordinate: RouteCoordinate(latitude: 35.005, longitude: 139.005),
            sourceRawRevision: 4,
            generatedAt: startDate.addingTimeInterval(700)
        )
    }

    private func requireSendable(_: some Sendable) {}
}
