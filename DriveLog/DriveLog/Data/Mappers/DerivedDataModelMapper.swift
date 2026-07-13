import Foundation

nonisolated struct DerivedDataModelMapper {
    private let routeEncoding: any RouteEncoding

    init(routeEncoding: any RouteEncoding) {
        self.routeEncoding = routeEncoding
    }

    func data(from model: DayProcessingStateModel) -> DayProcessingStateData {
        DayProcessingStateData(
            localDateKey: model.localDateKey, rawRevision: model.rawRevision,
            processedRevision: model.processedRevision,
            status: RawValueMapper.processingStatus(from: model.statusRawValue),
            lastAttemptDate: model.lastAttemptDate,
            lastSuccessfulDate: model.lastSuccessfulDate,
            lastErrorCode: model.lastErrorCode, updatedAt: model.updatedAt
        )
    }

    func model(from data: DayProcessingStateData, id: UUID = UUID()) -> DayProcessingStateModel {
        DayProcessingStateModel(
            id: id, localDateKey: data.localDateKey, rawRevision: data.rawRevision,
            processedRevision: data.processedRevision,
            statusRawValue: RawValueMapper.rawValue(for: data.status),
            lastAttemptDate: data.lastAttemptDate,
            lastSuccessfulDate: data.lastSuccessfulDate,
            lastErrorCode: data.lastErrorCode, updatedAt: data.updatedAt
        )
    }

    func data(from model: DayAggregateModel) -> DayAggregateData {
        DayAggregateData(
            localDateKey: model.localDateKey,
            totalDistanceMeters: model.totalDistanceMeters,
            totalMovementDurationSeconds: model.totalMovementDurationSeconds,
            startDate: model.startDate, endDate: model.endDate,
            locationRecordCount: model.locationRecordCount,
            rejectedLocationCount: model.rejectedLocationCount,
            mediaCountCache: model.mediaCountCache,
            automaticClassification: RawValueMapper.automaticMovementType(
                from: model.automaticClassificationRawValue
            ),
            hasValidMovement: model.hasValidMovement,
            movementSegmentCount: model.movementSegmentCount,
            staySegmentCount: model.staySegmentCount,
            totalStayDurationSeconds: model.totalStayDurationSeconds,
            automotiveDurationSeconds: model.automotiveDurationSeconds,
            walkingDurationSeconds: model.walkingDurationSeconds,
            sourceRawRevision: model.sourceRawRevision, generatedAt: model.generatedAt
        )
    }

    func model(from data: DayAggregateData, id: UUID = UUID()) -> DayAggregateModel {
        DayAggregateModel(
            id: id, localDateKey: data.localDateKey,
            totalDistanceMeters: data.totalDistanceMeters,
            totalMovementDurationSeconds: data.totalMovementDurationSeconds,
            startDate: data.startDate, endDate: data.endDate,
            locationRecordCount: data.locationRecordCount,
            rejectedLocationCount: data.rejectedLocationCount,
            mediaCountCache: data.mediaCountCache,
            automaticClassificationRawValue: RawValueMapper.rawValue(
                for: data.automaticClassification
            ),
            hasValidMovement: data.hasValidMovement,
            movementSegmentCount: data.movementSegmentCount,
            staySegmentCount: data.staySegmentCount,
            totalStayDurationSeconds: data.totalStayDurationSeconds,
            automotiveDurationSeconds: data.automotiveDurationSeconds,
            walkingDurationSeconds: data.walkingDurationSeconds,
            sourceRawRevision: data.sourceRawRevision, generatedAt: data.generatedAt
        )
    }

    func data(from model: MovementSegmentModel) throws -> MovementSegmentData {
        try MovementSegmentData(
            stableID: model.stableID, localDateKey: model.localDateKey,
            startDate: model.startDate, endDate: model.endDate,
            distanceMeters: model.distanceMeters, durationSeconds: model.durationSeconds,
            estimatedAverageSpeedMetersPerSecond: model.estimatedAverageSpeedMetersPerSecond,
            automaticClassification: RawValueMapper.automaticMovementType(
                from: model.automaticClassificationRawValue
            ),
            classificationConfidence: RawValueMapper.classificationConfidence(
                from: model.classificationConfidenceRawValue
            ),
            route: routeEncoding.decode(model.encodedRouteData),
            labelCoordinate: Self.coordinate(
                latitude: model.labelLatitude,
                longitude: model.labelLongitude
            ),
            sourceRawRevision: model.sourceRawRevision, generatedAt: model.generatedAt
        )
    }

    func model(from data: MovementSegmentData, id: UUID = UUID()) throws -> MovementSegmentModel {
        try MovementSegmentModel(
            id: id, stableID: data.stableID, localDateKey: data.localDateKey,
            startDate: data.startDate, endDate: data.endDate,
            distanceMeters: data.distanceMeters, durationSeconds: data.durationSeconds,
            estimatedAverageSpeedMetersPerSecond: data.estimatedAverageSpeedMetersPerSecond,
            automaticClassificationRawValue: RawValueMapper.rawValue(
                for: data.automaticClassification
            ),
            classificationConfidenceRawValue: RawValueMapper.rawValue(
                for: data.classificationConfidence
            ),
            encodedRouteData: routeEncoding.encode(data.route),
            labelLatitude: data.labelCoordinate?.latitude,
            labelLongitude: data.labelCoordinate?.longitude,
            sourceRawRevision: data.sourceRawRevision, generatedAt: data.generatedAt
        )
    }

    func data(from model: StaySegmentModel) -> StaySegmentData {
        StaySegmentData(
            stableID: model.stableID, localDateKey: model.localDateKey,
            representativeCoordinate: RouteCoordinate(
                latitude: model.representativeLatitude,
                longitude: model.representativeLongitude
            ),
            estimatedArrivalDate: model.estimatedArrivalDate,
            estimatedDepartureDate: model.estimatedDepartureDate,
            durationSeconds: model.durationSeconds,
            confidence: RawValueMapper.stayConfidence(from: model.confidenceRawValue),
            source: RawValueMapper.staySource(from: model.sourceRawValue),
            isVisibleByAutomaticRule: model.isVisibleByAutomaticRule,
            sourceRawRevision: model.sourceRawRevision, generatedAt: model.generatedAt
        )
    }

    func model(from data: StaySegmentData, id: UUID = UUID()) -> StaySegmentModel {
        StaySegmentModel(
            id: id, stableID: data.stableID, localDateKey: data.localDateKey,
            representativeLatitude: data.representativeCoordinate.latitude,
            representativeLongitude: data.representativeCoordinate.longitude,
            estimatedArrivalDate: data.estimatedArrivalDate,
            estimatedDepartureDate: data.estimatedDepartureDate,
            durationSeconds: data.durationSeconds,
            confidenceRawValue: RawValueMapper.rawValue(for: data.confidence),
            sourceRawValue: RawValueMapper.rawValue(for: data.source),
            isVisibleByAutomaticRule: data.isVisibleByAutomaticRule,
            sourceRawRevision: data.sourceRawRevision, generatedAt: data.generatedAt
        )
    }

    private static func coordinate(latitude: Double?, longitude: Double?) -> RouteCoordinate? {
        guard let latitude, let longitude else { return nil }
        return RouteCoordinate(latitude: latitude, longitude: longitude)
    }
}
