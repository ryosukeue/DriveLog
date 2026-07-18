@testable import DriveLog
import Testing

@Suite("Processing configuration")
struct ProcessingConfigurationTests {
    @Test("MVP location and segmentation values match processing rules")
    func locationAndSegmentation() {
        let configuration = ProcessingConfiguration.mvp

        #expect(configuration.location.futureTimestampTolerance == 86400)
        #expect(configuration.location.duplicateTimeInterval == 30)
        #expect(configuration.location.duplicateDistance == 10)
        #expect(configuration.location.maximumHorizontalAccuracy == 500)
        #expect(configuration.location.maximumPlausibleSpeed == 250 / 3.6)
        #expect(configuration.segmentation.maximumContinuousGap == 5400)
        #expect(configuration.segmentation.minimumSegmentDistance == 100)
        #expect(configuration.segmentation.minimumSegmentPointCount == 2)
        #expect(configuration.segmentation.minimumSpeedDisplayDuration == 120)
        #expect(configuration.segmentation.minimumSpeedDisplayDistance == 100)
        #expect(configuration.segmentation.minimumSpeedDisplayPointCount == 2)
        #expect(configuration.segmentation.stationaryDrift.minimumDuration == 300)
        #expect(configuration.segmentation.stationaryDrift.maximumAverageSpeed == 0.5)
        #expect(configuration.segmentation.stationaryDrift.maximumProgressRatio == 0.4)
        #expect(configuration.segmentation.stationaryDrift.minimumMotionEvidenceDuration == 180)
        #expect(configuration.segmentation.stationaryDrift.minimumStationaryMotionRatio == 0.6)
    }

    @Test("MVP stay classification and day values match processing rules")
    func stayClassificationAndDay() {
        let configuration = ProcessingConfiguration.mvp

        #expect(configuration.stay.minimumStayDuration == 180)
        #expect(configuration.stay.automaticStayDuration == 300)
        #expect(configuration.stay.stayRadius == 150)
        #expect(configuration.stay.trafficDirectionChangeToleranceDegrees == 45)
        #expect(configuration.classification.lowConfidenceWeight == 0.5)
        #expect(configuration.classification.mediumConfidenceWeight == 0.75)
        #expect(configuration.classification.highConfidenceWeight == 1)
        #expect(configuration.classification.automotiveMotionRatio == 0.5)
        #expect(configuration.classification.automotiveFallbackSpeed == 15 / 3.6)
        #expect(configuration.classification.automotiveFallbackDistance == 2000)
        #expect(configuration.classification.walkingMotionRatio == 0.4)
        #expect(configuration.classification.walkingFallbackMaximumSpeed == 8 / 3.6)
        #expect(configuration.classification.walkingFallbackMaximumDistance == 3000)
        #expect(configuration.classification.highConfidenceMinimumRatio == 0.7)
        #expect(configuration.classification.mediumConfidenceMinimumRatio == 0.4)
        #expect(configuration.dayValidation.minimumValidDayDistance == 1000)
        #expect(configuration.dayValidation.minimumValidMovementSegments == 1)
        #expect(configuration.dayValidation.minimumValidLocationPointCount == 2)
    }

    @Test("MVP override media and route values match processing rules")
    func overrideMediaAndRoute() {
        let configuration = ProcessingConfiguration.mvp

        #expect(configuration.overrideMatching.movementOverrideStartTolerance == 900)
        #expect(configuration.overrideMatching.movementOverrideEndTolerance == 900)
        #expect(configuration.overrideMatching.movementOverrideMinimumOverlap == 0.5)
        #expect(configuration.overrideMatching.stayOverrideArrivalTolerance == 900)
        #expect(configuration.overrideMatching.stayOverrideDepartureTolerance == 900)
        #expect(configuration.overrideMatching.stayOverrideCoordinateTolerance == 300)
        #expect(configuration.media.maximumRouteMediaDistance == 500)
        #expect(configuration.route.simplificationTolerance == 30)
        #expect(configuration.route.minimumPointCountForSimplification == 10)
        #expect(configuration.route.routeLabelPrimaryPosition == 0.5)
        #expect(configuration.route.routeLabelFallbackPositions == [0.4, 0.45, 0.55, 0.6])
    }

    @Test("configuration is equatable and sendable")
    func valueSemantics() {
        let configuration = ProcessingConfiguration.mvp
        requireSendable(configuration)

        #expect(configuration == ProcessingConfiguration.mvp)
        #expect(
            configuration.location != LocationRules(
                futureTimestampTolerance: 86400,
                duplicateTimeInterval: 30,
                duplicateDistance: 11,
                maximumHorizontalAccuracy: 500,
                maximumPlausibleSpeed: 250 / 3.6
            )
        )
    }

    private func requireSendable(_: some Sendable) {}
}
