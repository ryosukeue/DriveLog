import Foundation

nonisolated protocol ProcessingAlgorithmVersionStoring: Sendable {
    func storedVersion() async -> Int
    func setStoredVersion(_ version: Int) async
}

nonisolated protocol ProcessingAlgorithmMigrating: Sendable {
    func migrateIfNeeded() async
}

actor UserDefaultsAlgorithmVersionStore: ProcessingAlgorithmVersionStoring {
    private let key: String

    init(key: String = "processingAlgorithmVersion") {
        self.key = key
    }

    func storedVersion() -> Int {
        UserDefaults.standard.integer(forKey: key)
    }

    func setStoredVersion(_ version: Int) {
        UserDefaults.standard.set(version, forKey: key)
    }
}

actor DefaultProcessingAlgorithmMigrator: ProcessingAlgorithmMigrating {
    static let currentVersion = 7

    private let currentVersion: Int
    private let stateInvalidator: any ProcessingStateInvalidating
    private let versionStore: any ProcessingAlgorithmVersionStoring

    init(
        currentVersion: Int = DefaultProcessingAlgorithmMigrator.currentVersion,
        stateInvalidator: any ProcessingStateInvalidating,
        versionStore: any ProcessingAlgorithmVersionStoring
    ) {
        self.currentVersion = currentVersion
        self.stateInvalidator = stateInvalidator
        self.versionStore = versionStore
    }

    func migrateIfNeeded() async {
        guard await versionStore.storedVersion() < currentVersion else { return }
        do {
            try await stateInvalidator.invalidateProcessedDaysForAlgorithmUpdate()
            await versionStore.setStoredVersion(currentVersion)
        } catch {
            // The unchanged version makes the invalidation retry on the next launch.
        }
    }
}

nonisolated struct NoOpProcessingAlgorithmMigrator: ProcessingAlgorithmMigrating {
    func migrateIfNeeded() async {}
}
