import SwiftData

enum DriveLogSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            LocationEventModel.self,
            MotionEventModel.self,
            VisitEventModel.self,
            DayProcessingStateModel.self,
            DayAggregateModel.self,
            MovementSegmentModel.self,
            StaySegmentModel.self,
            ClassificationOverrideModel.self,
            StayOverrideModel.self,
            MediaAssetCacheModel.self
        ]
    }
}
