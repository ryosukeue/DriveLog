import Foundation

nonisolated enum ProcessingPriority: Int, Sendable {
    case background = 0
    case normal = 1
    case userVisible = 2

    var taskPriority: TaskPriority {
        switch self {
        case .background:
            .background
        case .normal:
            .medium
        case .userVisible:
            .userInitiated
        }
    }
}

nonisolated protocol DayProcessingGating: Sendable {
    func execute(
        localDateKey: String,
        priority: ProcessingPriority,
        operation: @escaping @Sendable () async throws -> DayProcessingResult
    ) async throws -> DayProcessingResult
    func cancelAll() async
}

actor DayProcessingGate: DayProcessingGating {
    typealias Operation = @Sendable () async throws -> DayProcessingResult

    private struct Entry {
        let id: UUID
        let task: Task<DayProcessingResult, any Error>
    }

    private var entries: [String: Entry] = [:]

    func execute(
        localDateKey: String,
        priority: ProcessingPriority,
        operation: @escaping Operation
    ) async throws -> DayProcessingResult {
        if let entry = entries[localDateKey] {
            return try await entry.task.value
        }

        let id = UUID()
        let task = Task.detached(priority: priority.taskPriority) {
            try await operation()
        }
        entries[localDateKey] = Entry(id: id, task: task)
        do {
            let result = try await task.value
            removeEntry(for: localDateKey, id: id)
            return result
        } catch {
            removeEntry(for: localDateKey, id: id)
            throw error
        }
    }

    func cancelAll() {
        entries.values.forEach { $0.task.cancel() }
    }

    private func removeEntry(for localDateKey: String, id: UUID) {
        guard entries[localDateKey]?.id == id else { return }
        entries[localDateKey] = nil
    }
}
