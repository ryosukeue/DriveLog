import SwiftData

@ModelActor
actor PersistenceActor {
    func count<Model: PersistentModel>(_: Model.Type) throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<Model>())
    }

    func saveIfNeeded() throws {
        guard modelContext.hasChanges else { return }
        try modelContext.save()
    }
}
