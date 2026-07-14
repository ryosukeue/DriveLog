nonisolated protocol DeleteDayLogUseCase: Sendable {
    func execute(localDateKey: String) async throws
}

nonisolated struct DefaultDeleteDayLogUseCase: DeleteDayLogUseCase {
    private let repository: any DayDeletionRepository
    private let logger: any Logging

    init(repository: any DayDeletionRepository, logger: any Logging) {
        self.repository = repository
        self.logger = logger
    }

    func execute(localDateKey: String) async throws {
        guard localDateKey.isEmpty == false else {
            throw DriveLogError.invalidData
        }
        do {
            try await repository.deleteDay(localDateKey: localDateKey)
            logger.info(.dayDeletionCompleted(localDateKey: localDateKey))
        } catch {
            let failure = normalized(error)
            logger.error(.dayDeletionFailed(
                localDateKey: localDateKey,
                code: failureCode(failure)
            ))
            throw failure
        }
    }

    private func normalized(_ error: any Error) -> DriveLogError {
        if let error = error as? DriveLogError {
            return error
        }
        return .persistenceFailure(code: "delete_day")
    }

    private func failureCode(_ error: DriveLogError) -> String {
        switch error {
        case .cancelled:
            "cancelled"
        case let .processingFailure(_, code), let .persistenceFailure(code), let .unknown(code):
            code
        default:
            "delete_day"
        }
    }
}
