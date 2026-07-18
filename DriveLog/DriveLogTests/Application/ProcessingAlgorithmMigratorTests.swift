@testable import DriveLog
import Testing

@Suite("Processing algorithm migrator")
struct ProcessingAlgorithmMigratorTests {
    @Test("uses processing algorithm version five")
    func currentVersion() {
        #expect(DefaultProcessingAlgorithmMigrator.currentVersion == 5)
    }

    @Test("invalidates and advances an older version exactly once")
    func versionUpgrade() async {
        let invalidator = AlgorithmStateInvalidatorFake()
        let store = AlgorithmVersionStoreFake(version: 1)
        let migrator = DefaultProcessingAlgorithmMigrator(
            currentVersion: 2,
            stateInvalidator: invalidator,
            versionStore: store
        )

        await migrator.migrateIfNeeded()
        await migrator.migrateIfNeeded()

        #expect(await invalidator.invalidationCount == 1)
        #expect(await store.version == 2)
    }

    @Test("keeps the old version when invalidation fails")
    func invalidationFailure() async {
        let invalidator = AlgorithmStateInvalidatorFake(fails: true)
        let store = AlgorithmVersionStoreFake(version: 1)
        let migrator = DefaultProcessingAlgorithmMigrator(
            currentVersion: 2,
            stateInvalidator: invalidator,
            versionStore: store
        )

        await migrator.migrateIfNeeded()
        await migrator.migrateIfNeeded()

        #expect(await invalidator.invalidationCount == 2)
        #expect(await store.version == 1)
    }

    @Test("skips invalidation when the stored version is current")
    func currentVersionSkipsInvalidation() async {
        let invalidator = AlgorithmStateInvalidatorFake()
        let store = AlgorithmVersionStoreFake(version: DefaultProcessingAlgorithmMigrator.currentVersion)
        let migrator = DefaultProcessingAlgorithmMigrator(
            stateInvalidator: invalidator,
            versionStore: store
        )

        await migrator.migrateIfNeeded()

        #expect(await invalidator.invalidationCount == 0)
        #expect(await store.version == DefaultProcessingAlgorithmMigrator.currentVersion)
    }
}

private actor AlgorithmStateInvalidatorFake: ProcessingStateInvalidating {
    private let fails: Bool
    private(set) var invalidationCount = 0

    init(fails: Bool = false) {
        self.fails = fails
    }

    func invalidateProcessedDaysForAlgorithmUpdate() async throws {
        invalidationCount += 1
        if fails {
            throw DriveLogError.persistenceFailure(code: "expected")
        }
    }
}

private actor AlgorithmVersionStoreFake: ProcessingAlgorithmVersionStoring {
    private(set) var version: Int

    init(version: Int) {
        self.version = version
    }

    func storedVersion() async -> Int {
        version
    }

    func setStoredVersion(_ version: Int) async {
        self.version = version
    }
}
