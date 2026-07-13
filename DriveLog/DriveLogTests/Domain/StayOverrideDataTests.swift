@testable import DriveLog
import Foundation
import Testing

@Suite("Stay and override data")
struct StayOverrideDataTests {
    @Test("Stay enums expose designed cases")
    func enumCases() {
        let confidence: [StayConfidence] = [.low, .medium, .high]
        let sources: [StayDetectionSource] = [.visit, .locationGap, .motionTransition, .combined]
        let actions: [StayOverrideAction] = [.confirm, .hide, .automatic]

        #expect(confidence[0] != confidence[1])
        #expect(sources[0] != sources[1])
        #expect(actions[0] != actions[1])
        requireSendable(confidence)
        requireSendable(sources)
        requireSendable(actions)
    }

    @Test("Stay segment preserves automatic decision data")
    func staySegmentPreservesValues() {
        let stay = makeStay(duration: 600)

        #expect(stay.representativeCoordinate == coordinate)
        #expect(stay.source == .combined)
        #expect(stay.isVisibleByAutomaticRule)
        #expect(stay == makeStay(duration: 600))
        #expect(stay != makeStay(duration: 601))
        requireSendable(stay)
    }

    @Test("Classification override remains separate from automatic type")
    func classificationOverridePreservesValues() {
        let override = makeClassificationOverride(.train)

        #expect(override.userClassification == .train)
        #expect(override == makeClassificationOverride(.train))
        #expect(override != makeClassificationOverride(.bus))
        requireSendable(override)
    }

    @Test("Stay override preserves original matching values")
    func stayOverridePreservesValues() {
        let override = makeStayOverride(.confirm)

        #expect(override.originalCoordinate == coordinate)
        #expect(override.action == .confirm)
        #expect(override == makeStayOverride(.confirm))
        #expect(override != makeStayOverride(.hide))
        requireSendable(override)
    }

    private var date: Date {
        Date(timeIntervalSince1970: 1_700_000_000)
    }

    private var coordinate: RouteCoordinate {
        RouteCoordinate(latitude: 35.0, longitude: 139.0)
    }

    private func makeStay(duration: Double) -> StaySegmentData {
        StaySegmentData(
            stableID: "stay-id",
            localDateKey: "2023-11-15",
            representativeCoordinate: coordinate,
            estimatedArrivalDate: date,
            estimatedDepartureDate: date.addingTimeInterval(duration),
            durationSeconds: duration,
            confidence: .high,
            source: .combined,
            isVisibleByAutomaticRule: true,
            sourceRawRevision: 4,
            generatedAt: date.addingTimeInterval(duration + 1)
        )
    }

    private func makeClassificationOverride(
        _ classification: UserMovementClassification
    ) -> ClassificationOverrideData {
        ClassificationOverrideData(
            overrideKey: "2023-11-15|movement-id",
            targetStableID: "movement-id",
            localDateKey: "2023-11-15",
            originalStartDate: date,
            originalEndDate: date.addingTimeInterval(600),
            userClassification: classification,
            createdAt: date,
            updatedAt: date
        )
    }

    private func makeStayOverride(_ action: StayOverrideAction) -> StayOverrideData {
        StayOverrideData(
            overrideKey: "2023-11-15|stay-id",
            targetStableID: "stay-id",
            localDateKey: "2023-11-15",
            originalArrivalDate: date,
            originalDepartureDate: date.addingTimeInterval(600),
            originalCoordinate: coordinate,
            action: action,
            createdAt: date,
            updatedAt: date
        )
    }

    private func requireSendable(_: some Sendable) {}
}
