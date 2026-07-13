import Foundation

enum RawEventModelMapper {
    static func data(from model: LocationEventModel) -> LocationEventData {
        LocationEventData(
            latitude: model.latitude, longitude: model.longitude, timestamp: model.timestamp,
            horizontalAccuracy: model.horizontalAccuracy,
            speedMetersPerSecond: model.speedMetersPerSecond, createdAt: model.createdAt,
            timeZoneIdentifier: model.timeZoneIdentifier,
            utcOffsetSeconds: model.utcOffsetSeconds, localDateKey: model.localDateKey
        )
    }

    static func model(
        from data: LocationEventData,
        id: UUID = UUID(),
        deduplicationKey: String
    ) -> LocationEventModel {
        LocationEventModel(
            id: id, latitude: data.latitude, longitude: data.longitude,
            timestamp: data.timestamp, horizontalAccuracy: data.horizontalAccuracy,
            speedMetersPerSecond: data.speedMetersPerSecond, createdAt: data.createdAt,
            timeZoneIdentifier: data.timeZoneIdentifier,
            utcOffsetSeconds: data.utcOffsetSeconds, localDateKey: data.localDateKey,
            deduplicationKey: deduplicationKey
        )
    }

    static func data(from model: MotionEventModel) -> MotionEventData {
        MotionEventData(
            startDate: model.startDate, endDate: model.endDate,
            isAutomotive: model.isAutomotive, isWalking: model.isWalking,
            isRunning: model.isRunning, isCycling: model.isCycling,
            isStationary: model.isStationary, isUnknown: model.isUnknown,
            confidence: RawValueMapper.motionConfidence(from: model.confidenceRawValue),
            timeZoneIdentifier: model.timeZoneIdentifier,
            utcOffsetSeconds: model.utcOffsetSeconds, localDateKey: model.localDateKey
        )
    }

    static func model(
        from data: MotionEventData,
        id: UUID = UUID(),
        createdAt: Date
    ) -> MotionEventModel {
        MotionEventModel(
            id: id, startDate: data.startDate, endDate: data.endDate,
            isAutomotive: data.isAutomotive, isWalking: data.isWalking,
            isRunning: data.isRunning, isCycling: data.isCycling,
            isStationary: data.isStationary, isUnknown: data.isUnknown,
            confidenceRawValue: RawValueMapper.rawValue(for: data.confidence),
            createdAt: createdAt, timeZoneIdentifier: data.timeZoneIdentifier,
            utcOffsetSeconds: data.utcOffsetSeconds, localDateKey: data.localDateKey
        )
    }

    static func data(from model: VisitEventModel) -> VisitEventData {
        VisitEventData(
            latitude: model.latitude, longitude: model.longitude,
            arrivalDate: model.arrivalDate, departureDate: model.departureDate,
            horizontalAccuracy: model.horizontalAccuracy,
            timeZoneIdentifier: model.timeZoneIdentifier,
            utcOffsetSeconds: model.utcOffsetSeconds, localDateKey: model.localDateKey
        )
    }

    static func model(
        from data: VisitEventData,
        id: UUID = UUID(),
        createdAt: Date,
        updatedAt: Date,
        visitMatchKey: String
    ) -> VisitEventModel {
        VisitEventModel(
            id: id, latitude: data.latitude, longitude: data.longitude,
            arrivalDate: data.arrivalDate, departureDate: data.departureDate,
            horizontalAccuracy: data.horizontalAccuracy, createdAt: createdAt,
            updatedAt: updatedAt, timeZoneIdentifier: data.timeZoneIdentifier,
            utcOffsetSeconds: data.utcOffsetSeconds, localDateKey: data.localDateKey,
            visitMatchKey: visitMatchKey
        )
    }
}
