@testable import DriveLog
import Foundation
import Testing

@Suite("Location processing diagnostics")
struct LocationProcessingDiagnosticsTests {
    // swiftlint:disable function_body_length
    @Test("summarizes pipeline counts without coordinates")
    func summarizesPipeline() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let received = [
            location(seconds: 0, accuracy: 10, base: base),
            location(seconds: 60, accuracy: 50, base: base),
            location(seconds: 1000, accuracy: 200, base: base),
            location(seconds: 7000, accuracy: 600, base: base)
        ]
        let candidate = MovementSegmentCandidate(
            localDateKey: "2023-11-15",
            startDate: received[0].timestamp,
            endDate: received[2].timestamp,
            locations: Array(received.prefix(3)),
            distanceMeters: 300
        )
        let value = LocationProcessingDiagnostics(
            received: received,
            sanitized: SanitizedLocations(
                accepted: Array(received.prefix(3)),
                rejected: [RejectedLocation(location: received[3], reason: .poorAccuracy)]
            ),
            segmentation: MovementSegmentationResult(
                segments: [candidate],
                gaps: [GapCandidate(
                    precedingLocation: received[2],
                    followingLocation: received[3],
                    reason: .continuousGap
                )],
                discardedSegments: []
            ),
            routePersistedPointCount: 2
        )

        #expect(value.receivedCount == 4)
        #expect(value.acceptedCount == 3)
        #expect(value.rejectionCounts == [.poorAccuracy: 1])
        #expect(value.accuracyCounts == .init(
            upToTwentyFiveMeters: 1,
            twentyFiveToOneHundredMeters: 1,
            oneHundredToFiveHundredMeters: 1,
            overFiveHundredMeters: 1,
            invalid: 0
        ))
        #expect(value.intervalCounts == .init(
            upToNinetySeconds: 1,
            ninetySecondsToFifteenMinutes: 0,
            fifteenToNinetyMinutes: 1,
            ninetyMinutesOrMore: 1,
            invalid: 0
        ))
        #expect(value.continuousGapCount == 1)
        #expect(value.routeInputPointCount == 3)
        #expect(value.routePersistedPointCount == 2)
    }

    // swiftlint:enable function_body_length

    private func location(
        seconds: TimeInterval,
        accuracy: Double,
        base: Date
    ) -> LocationEventData {
        LocationEventData(
            latitude: 35,
            longitude: 139,
            timestamp: base.addingTimeInterval(seconds),
            horizontalAccuracy: accuracy,
            speedMetersPerSecond: nil,
            createdAt: base,
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2023-11-15"
        )
    }
}
