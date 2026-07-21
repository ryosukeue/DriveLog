@testable import DriveLog
import Foundation
import Testing

@Suite("Vehicle movement evidence")
struct VehicleMovementEvidenceEvaluatorTests {
    private let evaluator = VehicleMovementEvidenceEvaluator()

    @Test("accepts a valid speed")
    func acceptsSpeed() {
        #expect(evaluator.confirmsMovement(location(speed: 4), after: nil))
    }

    @Test("accepts a displacement between accurate points")
    func acceptsDisplacement() {
        let previous = location(latitude: 35, longitude: 139)
        let current = location(
            latitude: 35.001, longitude: 139,
            timestamp: previous.timestamp.addingTimeInterval(30)
        )

        #expect(evaluator.confirmsMovement(current, after: previous))
    }

    @Test("rejects poor accuracy, insufficient movement, and stale points")
    func rejectsInvalidEvidence() {
        let previous = location(latitude: 35, longitude: 139)
        #expect(!evaluator.confirmsMovement(location(accuracy: 151), after: previous))
        #expect(!evaluator.confirmsMovement(
            location(latitude: 35.0001, longitude: 139, timestamp: previous.timestamp.addingTimeInterval(30)),
            after: previous
        ))
        #expect(!evaluator.confirmsMovement(
            location(latitude: 35.001, longitude: 139, timestamp: previous.timestamp.addingTimeInterval(91)),
            after: previous
        ))
        #expect(!evaluator.confirmsMovement(
            location(speed: 4, timestamp: previous.timestamp),
            after: previous
        ))
    }

    private func location(
        latitude: Double = 35,
        longitude: Double = 139,
        accuracy: Double = 50,
        speed: Double? = nil,
        timestamp: Date = Date(timeIntervalSince1970: 1_704_067_200)
    ) -> LocationEventData {
        LocationEventData(
            latitude: latitude, longitude: longitude, timestamp: timestamp,
            horizontalAccuracy: accuracy, speedMetersPerSecond: speed,
            createdAt: timestamp, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: "2024-01-01"
        )
    }
}
