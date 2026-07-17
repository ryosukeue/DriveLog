import Foundation
import SwiftData

extension PersistenceActor {
    func processingState(for localDateKey: String, createAt: Date) throws -> DayProcessingStateData {
        let state = try findOrCreateProcessingState(for: localDateKey, at: createAt)
        try saveIfNeeded()
        return Self.data(from: state)
    }

    func pendingProcessingDateKeys() throws -> [String] {
        let descriptor = FetchDescriptor<DayProcessingStateModel>(
            sortBy: [SortDescriptor(\DayProcessingStateModel.localDateKey)]
        )
        return try modelContext.fetch(descriptor).filter { state in
            state.rawRevision > state.processedRevision &&
                (
                    state.statusRawValue == "pending" ||
                        state.statusRawValue == "processing" ||
                        state.statusRawValue == "failed"
                )
        }.map(\.localDateKey)
    }

    func markProcessingDirty(localDateKey: String, updatedAt: Date) throws {
        let state = try findOrCreateProcessingState(for: localDateKey, at: updatedAt)
        state.rawRevision += 1
        state.statusRawValue = "pending"
        state.lastErrorCode = nil
        state.updatedAt = updatedAt
        try modelContext.save()
    }

    func markProcessing(
        localDateKey: String,
        attemptedAt: Date
    ) throws -> DayProcessingRevision {
        let state = try findOrCreateProcessingState(for: localDateKey, at: attemptedAt)
        state.statusRawValue = "processing"
        state.lastAttemptDate = attemptedAt
        state.lastErrorCode = nil
        state.updatedAt = attemptedAt
        let revision = DayProcessingRevision(
            rawRevision: state.rawRevision,
            processedRevision: state.processedRevision
        )
        try modelContext.save()
        return revision
    }

    func markProcessingCompleted(
        localDateKey: String,
        processedRevision: Int,
        completedAt: Date
    ) throws {
        let state = try findOrCreateProcessingState(for: localDateKey, at: completedAt)
        state.processedRevision = processedRevision
        state.statusRawValue = state.rawRevision == processedRevision ? "completed" : "pending"
        state.lastSuccessfulDate = completedAt
        state.lastErrorCode = nil
        state.updatedAt = completedAt
        try modelContext.save()
    }

    func markProcessingFailed(localDateKey: String, code: String, failedAt: Date) throws {
        let state = try findOrCreateProcessingState(for: localDateKey, at: failedAt)
        state.statusRawValue = "failed"
        state.lastErrorCode = code
        state.updatedAt = failedAt
        try modelContext.save()
    }

    func deleteProcessingState(for localDateKey: String) throws {
        if let state = try fetchProcessingState(for: localDateKey) {
            modelContext.delete(state)
            try modelContext.save()
        }
    }

    private func findOrCreateProcessingState(
        for localDateKey: String,
        at date: Date
    ) throws -> DayProcessingStateModel {
        if let state = try fetchProcessingState(for: localDateKey) {
            return state
        }
        let state = DayProcessingStateModel(
            localDateKey: localDateKey,
            rawRevision: 0,
            processedRevision: 0,
            statusRawValue: "pending",
            lastAttemptDate: nil,
            lastSuccessfulDate: nil,
            lastErrorCode: nil,
            updatedAt: date
        )
        modelContext.insert(state)
        return state
    }

    private func fetchProcessingState(for localDateKey: String) throws -> DayProcessingStateModel? {
        var descriptor = FetchDescriptor<DayProcessingStateModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private static func data(from model: DayProcessingStateModel) -> DayProcessingStateData {
        DayProcessingStateData(
            localDateKey: model.localDateKey,
            rawRevision: model.rawRevision,
            processedRevision: model.processedRevision,
            status: RawValueMapper.processingStatus(from: model.statusRawValue),
            lastAttemptDate: model.lastAttemptDate,
            lastSuccessfulDate: model.lastSuccessfulDate,
            lastErrorCode: model.lastErrorCode,
            updatedAt: model.updatedAt
        )
    }
}
