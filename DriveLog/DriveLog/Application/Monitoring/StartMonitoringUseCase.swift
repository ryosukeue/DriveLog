actor StartMonitoringUseCase {
    private let locationProvider: any LocationProviding
    private let motionProvider: any MotionProviding
    private let visitProvider: any VisitProviding
    private let storageCoordinator: RawEventStorageCoordinator
    private let powerStateProvider: any PowerStateProviding
    private let logger: any Logging
    private var isExecuting = false
    private var powerObservationTask: Task<Void, Never>?
    private var appliedLocationMode: LocationRecordingMode?

    init(
        locationProvider: any LocationProviding,
        motionProvider: any MotionProviding,
        visitProvider: any VisitProviding,
        storageCoordinator: RawEventStorageCoordinator,
        powerStateProvider: any PowerStateProviding,
        logger: any Logging
    ) {
        self.locationProvider = locationProvider
        self.motionProvider = motionProvider
        self.visitProvider = visitProvider
        self.storageCoordinator = storageCoordinator
        self.powerStateProvider = powerStateProvider
        self.logger = logger
    }

    func execute() async throws {
        guard !isExecuting else { return }
        isExecuting = true
        defer { isExecuting = false }

        await storageCoordinator.start()
        do {
            try await applyLocationMode(for: powerStateProvider.current)
        } catch {
            await storageCoordinator.stop()
            throw error
        }
        await startMotionIfNeeded()
        await startVisitIfNeeded()
        startPowerObservationIfNeeded()
    }

    private func applyLocationMode(for powerState: PowerState) async throws {
        let mode = powerState.locationRecordingMode
        let monitoringState = await locationProvider.monitoringState
        if appliedLocationMode == nil, monitoringState == .running, mode == .lowPower {
            appliedLocationMode = mode
            return
        }
        guard appliedLocationMode != mode || monitoringState != .running else {
            return
        }
        try await locationProvider.setRecordingMode(mode)
        appliedLocationMode = mode
        logger.info(.locationMonitoringStarted)
        logger.info(.locationRecordingModeChanged(modeCode: mode.rawValue))
    }

    private func startPowerObservationIfNeeded() {
        guard powerObservationTask == nil else { return }
        let changes = powerStateProvider.changes
        powerObservationTask = Task { [weak self] in
            for await state in changes {
                guard !Task.isCancelled else { return }
                await self?.applyObservedLocationMode(for: state)
            }
        }
    }

    private func applyObservedLocationMode(for powerState: PowerState) async {
        do {
            try await applyLocationMode(for: powerState)
        } catch {
            logger.error(.locationRecordingModeChangeFailed(
                modeCode: powerState.locationRecordingMode.rawValue,
                reasonCode: modeChangeFailureCode(error)
            ))
        }
    }

    private func modeChangeFailureCode(_ error: Error) -> String {
        switch error {
        case DriveLogError.permissionDenied:
            "permission_denied"
        case DriveLogError.permissionRestricted:
            "permission_restricted"
        case DriveLogError.monitoringUnavailable:
            "monitoring_unavailable"
        default:
            "location_mode_change_failed"
        }
    }

    private func startMotionIfNeeded() async {
        switch await motionProvider.monitoringState {
        case .starting, .running:
            return
        case .stopped, .unavailable, .failed:
            try? await motionProvider.startMonitoring()
        }
    }

    private func startVisitIfNeeded() async {
        switch await visitProvider.monitoringState {
        case .starting, .running:
            return
        case .stopped, .unavailable, .failed:
            try? await visitProvider.startMonitoring()
        }
    }
}
