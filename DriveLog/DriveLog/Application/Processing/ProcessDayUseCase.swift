import Foundation

nonisolated protocol ProcessDayUseCase: Sendable {
    func execute(localDateKey: String) async throws -> DayProcessingResult
}

nonisolated struct DefaultProcessDayUseCase: ProcessDayUseCase {
    typealias MediaCountLoader = @Sendable (String) async throws -> Int

    private let stateRepository: any ProcessingStateRepository
    private let rawRepository: any RawEventRepository
    private let overrideRepository: any OverrideRepository
    private let derivedRepository: any DerivedDataRepository
    private let processor: any DayProcessing
    private let mediaCountLoader: MediaCountLoader
    private let vehicleDistanceRecorder: (any VehicleProcessedDistanceRecording)?
    private let oilChangeNotifier: any VehicleOilChangeNotifying
    private let clock: any Clock
    private let logger: any Logging

    init(
        stateRepository: any ProcessingStateRepository,
        rawRepository: any RawEventRepository,
        overrideRepository: any OverrideRepository,
        derivedRepository: any DerivedDataRepository,
        processor: any DayProcessing,
        mediaCountLoader: @escaping MediaCountLoader = { _ in 0 },
        vehicleDistanceRecorder: (any VehicleProcessedDistanceRecording)? = nil,
        oilChangeNotifier: any VehicleOilChangeNotifying = EmptyVehicleOilChangeNotifier(),
        clock: any Clock = SystemClock(),
        logger: any Logging = OSLogLogger()
    ) {
        self.stateRepository = stateRepository
        self.rawRepository = rawRepository
        self.overrideRepository = overrideRepository
        self.derivedRepository = derivedRepository
        self.processor = processor
        self.mediaCountLoader = mediaCountLoader
        self.vehicleDistanceRecorder = vehicleDistanceRecorder
        self.oilChangeNotifier = oilChangeNotifier
        self.clock = clock
        self.logger = logger
    }

    func execute(localDateKey: String) async throws -> DayProcessingResult {
        do {
            let state = try await stateRepository.state(for: localDateKey)
            if state.status == .completed, state.rawRevision == state.processedRevision {
                return try await storedResult(for: localDateKey)
            }
            return try await processAndStore(localDateKey: localDateKey)
        } catch {
            let failure = normalized(error, localDateKey: localDateKey)
            let code = failureCode(for: failure)
            try? await stateRepository.markFailed(
                localDateKey: localDateKey,
                code: code,
                failedAt: clock.now
            )
            logger.error(.dayProcessingFailed(localDateKey: localDateKey, code: code))
            throw failure
        }
    }

    private func processAndStore(localDateKey: String) async throws -> DayProcessingResult {
        logger.info(.dayProcessingStarted(localDateKey: localDateKey))
        let revision = try await stateRepository.markProcessing(
            localDateKey: localDateKey,
            attemptedAt: clock.now
        )
        let rawEvents = try await rawRepository.rawEvents(for: localDateKey)
        let classificationOverrides = try await overrideRepository.classificationOverrides(
            for: localDateKey
        )
        let stayOverrides = try await overrideRepository.stayOverrides(for: localDateKey)
        let mediaCount = try await mediaCountLoader(localDateKey)
        let input = RawDayEvents(
            locations: rawEvents.locations,
            motions: rawEvents.motions,
            visits: rawEvents.visits,
            classificationOverrides: classificationOverrides,
            stayOverrides: stayOverrides
        )
        let result = try await processor.process(
            localDateKey: localDateKey,
            rawEvents: input,
            mediaCount: mediaCount,
            rawRevision: revision.rawRevision
        )
        try Task.checkCancellation()
        try await derivedRepository.replaceDerivedData(
            for: localDateKey,
            result: result,
            processedRevision: revision.rawRevision
        )
        let oilChangeNotifications = vehicleDistanceRecorder?.replaceProcessedDistances(
            for: localDateKey,
            movements: result.movements
        ) ?? []
        try await stateRepository.markCompleted(
            localDateKey: localDateKey,
            processedRevision: revision.rawRevision,
            completedAt: clock.now
        )
        for notification in oilChangeNotifications {
            await oilChangeNotifier.send(notification)
        }
        logger.info(.dayProcessingCompleted(localDateKey: localDateKey))
        return result
    }

    private func storedResult(for localDateKey: String) async throws -> DayProcessingResult {
        guard let aggregate = try await derivedRepository.aggregate(for: localDateKey) else {
            throw DriveLogError.invalidData
        }
        async let movements = derivedRepository.movementSegments(for: localDateKey)
        async let stays = derivedRepository.staySegments(for: localDateKey)
        return try await DayProcessingResult(
            aggregate: aggregate,
            movements: movements,
            stays: stays
        )
    }

    private func normalized(_ error: any Error, localDateKey: String) -> DriveLogError {
        if error is CancellationError {
            return .cancelled
        }
        if let error = error as? DriveLogError {
            return error
        }
        return .processingFailure(localDateKey: localDateKey, code: "process_day")
    }

    private func failureCode(for error: DriveLogError) -> String {
        switch error {
        case .cancelled:
            "cancelled"
        case let .processingFailure(_, code), let .persistenceFailure(code), let .unknown(code):
            code
        default:
            "process_day"
        }
    }
}
