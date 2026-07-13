import Foundation

nonisolated protocol DayProcessingCoordinating: Sendable {
    func processIfNeeded(localDateKey: String, priority: ProcessingPriority) async
    func processPendingDays(limit: Int) async
    func cancelCurrentProcessing() async
}

actor DefaultDayProcessingCoordinator: DayProcessingCoordinating {
    private let stateRepository: any ProcessingStateRepository
    private let processDayUseCase: any ProcessDayUseCase
    private let gate: any DayProcessingGating
    private var activeBatchID: UUID?

    init(
        stateRepository: any ProcessingStateRepository,
        processDayUseCase: any ProcessDayUseCase,
        gate: any DayProcessingGating = DayProcessingGate()
    ) {
        self.stateRepository = stateRepository
        self.processDayUseCase = processDayUseCase
        self.gate = gate
    }

    func processIfNeeded(localDateKey: String, priority: ProcessingPriority) async {
        let useCase = processDayUseCase
        _ = try? await gate.execute(localDateKey: localDateKey, priority: priority) {
            try await useCase.execute(localDateKey: localDateKey)
        }
    }

    func processPendingDays(limit: Int) async {
        guard limit > 0 else { return }
        let batchID = UUID()
        activeBatchID = batchID
        guard let dateKeys = try? await stateRepository.pendingDateKeys() else {
            finishBatch(id: batchID)
            return
        }

        for localDateKey in dateKeys.prefix(limit) {
            guard activeBatchID == batchID else { return }
            await processIfNeeded(localDateKey: localDateKey, priority: .background)
        }
        finishBatch(id: batchID)
    }

    func cancelCurrentProcessing() async {
        activeBatchID = nil
        await gate.cancelAll()
    }

    private func finishBatch(id: UUID) {
        guard activeBatchID == id else { return }
        activeBatchID = nil
    }
}
