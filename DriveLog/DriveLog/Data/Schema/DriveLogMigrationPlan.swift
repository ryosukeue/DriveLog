import SwiftData

enum DriveLogMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DriveLogSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
