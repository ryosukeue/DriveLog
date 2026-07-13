import SwiftData

enum DriveLogModelContainerFactory {
    static func make(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: DriveLogSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: DriveLogMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
