@testable import DriveLog
import Foundation
import Testing

@Suite("Data mappers")
@MainActor
struct DataMapperTests {
    @Test("Raw event models round-trip domain data")
    func rawEventsRoundTrip() {
        let location = LocationEventData(
            latitude: 35, longitude: 139, timestamp: date, horizontalAccuracy: 8,
            speedMetersPerSecond: 4, createdAt: laterDate,
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: localDateKey
        )
        let motion = MotionEventData(
            startDate: date, endDate: laterDate, isAutomotive: true, isWalking: false,
            isRunning: false, isCycling: false, isStationary: false, isUnknown: false,
            confidence: .high, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: localDateKey
        )
        let visit = VisitEventData(
            latitude: 35.1, longitude: 139.1, arrivalDate: date,
            departureDate: laterDate, horizontalAccuracy: 12,
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: localDateKey
        )

        let locationModel = RawEventModelMapper.model(
            from: location, deduplicationKey: "location-key"
        )
        let motionModel = RawEventModelMapper.model(from: motion, createdAt: laterDate)
        let visitModel = RawEventModelMapper.model(
            from: visit, createdAt: date, updatedAt: laterDate, visitMatchKey: "visit-key"
        )

        #expect(RawEventModelMapper.data(from: locationModel) == location)
        #expect(RawEventModelMapper.data(from: motionModel) == motion)
        #expect(RawEventModelMapper.data(from: visitModel) == visit)
        #expect(locationModel.deduplicationKey == "location-key")
        #expect(motionModel.createdAt == laterDate)
        #expect(visitModel.visitMatchKey == "visit-key")
    }

    @Test("Processing and aggregate models round-trip domain data")
    func dayDataRoundTrips() {
        let mapper = DerivedDataModelMapper(routeEncoding: FakeRouteEncoding())
        let state = DayProcessingStateData(
            localDateKey: localDateKey, rawRevision: 3, processedRevision: 2,
            status: .failed, lastAttemptDate: date, lastSuccessfulDate: nil,
            lastErrorCode: "processing", updatedAt: laterDate
        )
        let aggregate = DayAggregateData(
            localDateKey: localDateKey, totalDistanceMeters: 1200,
            totalMovementDurationSeconds: 600, startDate: date, endDate: laterDate,
            locationRecordCount: 12, rejectedLocationCount: 2, mediaCountCache: 3,
            automaticClassification: .automotiveLike, hasValidMovement: true,
            movementSegmentCount: 2, staySegmentCount: 1,
            totalStayDurationSeconds: 300, automotiveDurationSeconds: 500,
            walkingDurationSeconds: 100, sourceRawRevision: 3, generatedAt: laterDate
        )

        #expect(mapper.data(from: mapper.model(from: state)) == state)
        #expect(mapper.data(from: mapper.model(from: aggregate)) == aggregate)
    }

    @Test("Movement and stay models round-trip domain data through injected route encoding")
    func derivedDataRoundTrips() throws {
        let mapper = DerivedDataModelMapper(routeEncoding: FakeRouteEncoding())
        let route = [
            RouteCoordinate(latitude: 35, longitude: 139),
            RouteCoordinate(latitude: 35.1, longitude: 139.1)
        ]
        let movement = MovementSegmentData(
            stableID: "movement", localDateKey: localDateKey, startDate: date,
            endDate: laterDate, distanceMeters: 1200, durationSeconds: 600,
            estimatedAverageSpeedMetersPerSecond: 2,
            automaticClassification: .walkingLike, classificationConfidence: .medium,
            route: route, labelCoordinate: route.first, sourceRawRevision: 4,
            generatedAt: laterDate
        )
        let stay = StaySegmentData(
            stableID: "stay", localDateKey: localDateKey,
            representativeCoordinate: route[0], estimatedArrivalDate: date,
            estimatedDepartureDate: laterDate, durationSeconds: 600,
            confidence: .high, source: .combined, isVisibleByAutomaticRule: true,
            sourceRawRevision: 4, generatedAt: laterDate
        )

        #expect(try mapper.data(from: mapper.model(from: movement)) == movement)
        #expect(mapper.data(from: mapper.model(from: stay)) == stay)
    }

    @Test("Override and media cache models round-trip domain data")
    func overridesAndMediaRoundTrip() {
        let classification = ClassificationOverrideData(
            overrideKey: "day|movement", targetStableID: "movement",
            localDateKey: localDateKey, originalStartDate: date,
            originalEndDate: laterDate, userClassification: .train,
            createdAt: date, updatedAt: laterDate
        )
        let stay = StayOverrideData(
            overrideKey: "day|stay", targetStableID: "stay", localDateKey: localDateKey,
            originalArrivalDate: date, originalDepartureDate: laterDate,
            originalCoordinate: RouteCoordinate(latitude: 35, longitude: 139),
            action: .confirm, createdAt: date, updatedAt: laterDate
        )
        let media = MediaAssetReference(
            localIdentifier: "asset", mediaType: .video, creationDate: date,
            location: RouteCoordinate(latitude: 35, longitude: 139),
            durationSeconds: 10, isScreenshot: false, isScreenRecording: true
        )

        #expect(
            OverrideMediaModelMapper.data(
                from: OverrideMediaModelMapper.model(from: classification)
            ) == classification
        )
        #expect(
            OverrideMediaModelMapper.data(from: OverrideMediaModelMapper.model(from: stay)) == stay
        )
        let mediaModel = OverrideMediaModelMapper.model(
            from: media, localDateKey: localDateKey, eligibility: .eligible,
            lastValidatedAt: laterDate
        )
        #expect(OverrideMediaModelMapper.reference(from: mediaModel) == media)
        #expect(mediaModel.eligibilityRawValue == "eligible")
        #expect(mediaModel.lastValidatedAt == laterDate)
    }

    @Test("Unknown raw values use conservative fallbacks")
    func unknownValuesUseFallbacks() {
        #expect(RawValueMapper.motionConfidence(from: 99) == .low)
        #expect(RawValueMapper.processingStatus(from: "unknown") == .pending)
        #expect(RawValueMapper.automaticMovementType(from: "unknown") == .other)
        #expect(RawValueMapper.classificationConfidence(from: "unknown") == .low)
        #expect(RawValueMapper.userClassification(from: "unknown") == .other)
        #expect(RawValueMapper.stayConfidence(from: "unknown") == .low)
        #expect(RawValueMapper.staySource(from: "unknown") == .locationGap)
        #expect(RawValueMapper.stayAction(from: "unknown") == .automatic)
        #expect(RawValueMapper.mediaType(from: "unknown") == .photo)
        #expect(RawValueMapper.mediaEligibility(from: "unknown") == .ineligible)
    }

    @Test("Every designed enum case round-trips its raw value")
    func enumCasesRoundTripRawValues() {
        for value in [MotionConfidence.low, .medium, .high] {
            #expect(RawValueMapper.motionConfidence(from: RawValueMapper.rawValue(for: value)) == value)
        }
        for value in [ProcessingStatus.pending, .processing, .completed, .failed] {
            #expect(RawValueMapper.processingStatus(from: RawValueMapper.rawValue(for: value)) == value)
        }
        for value in [AutomaticMovementType.automotiveLike, .walkingLike, .other] {
            #expect(RawValueMapper.automaticMovementType(from: RawValueMapper.rawValue(for: value)) == value)
        }
        for value in [ClassificationConfidence.low, .medium, .high] {
            #expect(RawValueMapper.classificationConfidence(from: RawValueMapper.rawValue(for: value)) == value)
        }
        for value in [
            UserMovementClassification.automotive, .train, .bus, .walking, .other
        ] {
            #expect(RawValueMapper.userClassification(from: RawValueMapper.rawValue(for: value)) == value)
        }
        for value in [StayConfidence.low, .medium, .high] {
            #expect(RawValueMapper.stayConfidence(from: RawValueMapper.rawValue(for: value)) == value)
        }
        for value in [
            StayDetectionSource.visit, .locationGap, .motionTransition, .combined
        ] {
            #expect(RawValueMapper.staySource(from: RawValueMapper.rawValue(for: value)) == value)
        }
        for value in [StayOverrideAction.confirm, .hide, .automatic] {
            #expect(RawValueMapper.stayAction(from: RawValueMapper.rawValue(for: value)) == value)
        }
        for value in [MediaType.photo, .video] {
            #expect(RawValueMapper.mediaType(from: RawValueMapper.rawValue(for: value)) == value)
        }
        for value in [MediaEligibility.eligible, .ineligible] {
            #expect(RawValueMapper.mediaEligibility(from: RawValueMapper.rawValue(for: value)) == value)
        }
    }

    @Test("Route encoding failures propagate")
    func routeEncodingFailurePropagates() {
        let mapper = DerivedDataModelMapper(routeEncoding: FailingRouteEncoding())
        let model = MovementSegmentModel(
            stableID: "movement", localDateKey: localDateKey, startDate: date,
            endDate: laterDate, distanceMeters: 1, durationSeconds: 1,
            estimatedAverageSpeedMetersPerSecond: nil,
            automaticClassificationRawValue: "other",
            classificationConfidenceRawValue: "low", encodedRouteData: Data(),
            labelLatitude: nil, labelLongitude: nil, sourceRawRevision: 1,
            generatedAt: laterDate
        )

        #expect(throws: DriveLogError.self) {
            try mapper.data(from: model)
        }
    }

    private var date: Date {
        Date(timeIntervalSince1970: 1_700_000_000)
    }

    private var laterDate: Date {
        date.addingTimeInterval(600)
    }

    private var localDateKey: String {
        "2023-11-15"
    }
}

private struct FakeRouteEncoding: RouteEncoding {
    func encode(_ route: [RouteCoordinate]) throws -> Data {
        try JSONEncoder().encode(route.map { [$0.latitude, $0.longitude] })
    }

    func decode(_ data: Data) throws -> [RouteCoordinate] {
        try JSONDecoder().decode([[Double]].self, from: data).compactMap { values in
            guard values.count == 2 else { return nil }
            return RouteCoordinate(latitude: values[0], longitude: values[1])
        }
    }
}

private struct FailingRouteEncoding: RouteEncoding {
    func encode(_: [RouteCoordinate]) throws -> Data {
        throw DriveLogError.invalidData
    }

    func decode(_: Data) throws -> [RouteCoordinate] {
        throw DriveLogError.invalidData
    }
}
