import Foundation

enum OverrideMediaModelMapper {
    static func data(from model: ClassificationOverrideModel) -> ClassificationOverrideData {
        ClassificationOverrideData(
            overrideKey: model.overrideKey, targetStableID: model.targetStableID,
            localDateKey: model.localDateKey, originalStartDate: model.originalStartDate,
            originalEndDate: model.originalEndDate,
            userClassification: RawValueMapper.userClassification(
                from: model.userClassificationRawValue
            ),
            createdAt: model.createdAt, updatedAt: model.updatedAt
        )
    }

    static func model(
        from data: ClassificationOverrideData,
        id: UUID = UUID()
    ) -> ClassificationOverrideModel {
        ClassificationOverrideModel(
            id: id, overrideKey: data.overrideKey, targetStableID: data.targetStableID,
            localDateKey: data.localDateKey, originalStartDate: data.originalStartDate,
            originalEndDate: data.originalEndDate,
            userClassificationRawValue: RawValueMapper.rawValue(for: data.userClassification),
            createdAt: data.createdAt, updatedAt: data.updatedAt
        )
    }

    static func data(from model: StayOverrideModel) -> StayOverrideData {
        StayOverrideData(
            overrideKey: model.overrideKey, targetStableID: model.targetStableID,
            localDateKey: model.localDateKey, originalArrivalDate: model.originalArrivalDate,
            originalDepartureDate: model.originalDepartureDate,
            originalCoordinate: RouteCoordinate(
                latitude: model.originalLatitude, longitude: model.originalLongitude
            ),
            action: RawValueMapper.stayAction(from: model.actionRawValue),
            createdAt: model.createdAt, updatedAt: model.updatedAt
        )
    }

    static func model(from data: StayOverrideData, id: UUID = UUID()) -> StayOverrideModel {
        StayOverrideModel(
            id: id, overrideKey: data.overrideKey, targetStableID: data.targetStableID,
            localDateKey: data.localDateKey, originalArrivalDate: data.originalArrivalDate,
            originalDepartureDate: data.originalDepartureDate,
            originalLatitude: data.originalCoordinate.latitude,
            originalLongitude: data.originalCoordinate.longitude,
            actionRawValue: RawValueMapper.rawValue(for: data.action),
            createdAt: data.createdAt, updatedAt: data.updatedAt
        )
    }

    static func reference(from model: MediaAssetCacheModel) -> MediaAssetReference {
        MediaAssetReference(
            localIdentifier: model.localIdentifier,
            mediaType: RawValueMapper.mediaType(from: model.mediaTypeRawValue),
            creationDate: model.creationDate,
            location: coordinate(latitude: model.latitude, longitude: model.longitude),
            durationSeconds: model.durationSeconds, isScreenshot: model.isScreenshot,
            isScreenRecording: model.isScreenRecording
        )
    }

    static func model(
        from reference: MediaAssetReference,
        id: UUID = UUID(),
        localDateKey: String,
        eligibility: MediaEligibility,
        lastValidatedAt: Date
    ) -> MediaAssetCacheModel {
        MediaAssetCacheModel(
            id: id, localIdentifier: reference.localIdentifier, localDateKey: localDateKey,
            mediaTypeRawValue: RawValueMapper.rawValue(for: reference.mediaType),
            creationDate: reference.creationDate, latitude: reference.location?.latitude,
            longitude: reference.location?.longitude,
            durationSeconds: reference.durationSeconds, isScreenshot: reference.isScreenshot,
            isScreenRecording: reference.isScreenRecording,
            eligibilityRawValue: RawValueMapper.rawValue(for: eligibility),
            lastValidatedAt: lastValidatedAt
        )
    }

    private static func coordinate(latitude: Double?, longitude: Double?) -> RouteCoordinate? {
        guard let latitude, let longitude else { return nil }
        return RouteCoordinate(latitude: latitude, longitude: longitude)
    }
}
