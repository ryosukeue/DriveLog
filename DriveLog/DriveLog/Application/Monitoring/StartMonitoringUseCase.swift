nonisolated protocol RecordingStarting: Sendable {
    func startHighDensityRecording() async throws
}

actor StartMonitoringUseCase: RecordingStarting {
    private let locationProvider: any LocationProviding
    private let motionProvider: any MotionProviding
    private let visitProvider: any VisitProviding
    private let storageCoordinator: RawEventStorageCoordinator
    private let powerStateProvider: any PowerStateProviding
    private let logger: any Logging
    private var isExecuting = false
    private var powerObservationTask: Task<Void, Never>?
    private var locationObservationTask: Task<Void, Never>?
    private var activityObservationTask: Task<Void, Never>?
    private var vehicleCandidateTask: Task<Void, Never>?
    private var vehicleStopTask: Task<Void, Never>?
    private var appliedLocationMode: LocationRecordingMode?
    private var lastObservedPowerState: PowerState?
    private var lastLoggedModeFailure: ModeFailure?
    private var lastLoggedVehicleState: VehicleRecordingState?
    private var vehicleStateMachine = VehicleRecordingStateMachine()
    private var isManualHighDensityRecording = false
    private let vehicleMovementEvidenceEvaluator: VehicleMovementEvidenceEvaluator
    private var lastVehicleEvidenceLocation: LocationEventData?
    private var vehicleEvidenceCount = 0
    private let vehicleStopGracePeriod: Duration
    private let vehicleCandidateTimeout: Duration

    init(
        locationProvider: any LocationProviding,
        motionProvider: any MotionProviding,
        visitProvider: any VisitProviding,
        storageCoordinator: RawEventStorageCoordinator,
        powerStateProvider: any PowerStateProviding,
        logger: any Logging,
        vehicleStopGracePeriod: Duration = .seconds(180),
        vehicleCandidateTimeout: Duration = .seconds(90),
        vehicleMovementEvidenceEvaluator: VehicleMovementEvidenceEvaluator = .init()
    ) {
        self.locationProvider = locationProvider
        self.motionProvider = motionProvider
        self.visitProvider = visitProvider
        self.storageCoordinator = storageCoordinator
        self.powerStateProvider = powerStateProvider
        self.logger = logger
        self.vehicleMovementEvidenceEvaluator = vehicleMovementEvidenceEvaluator
        self.vehicleStopGracePeriod = vehicleStopGracePeriod
        self.vehicleCandidateTimeout = vehicleCandidateTimeout
    }

    deinit {
        powerObservationTask?.cancel()
        locationObservationTask?.cancel()
        activityObservationTask?.cancel()
        vehicleStopTask?.cancel()
        vehicleCandidateTask?.cancel()
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
        startLocationObservationIfNeeded()
        await startMotionIfNeeded()
        startActivityObservationIfNeeded()
        await startVisitIfNeeded()
        startPowerObservationIfNeeded()
    }

    func startHighDensityRecording() async throws {
        isManualHighDensityRecording = true
        vehicleCandidateTask?.cancel()
        vehicleCandidateTask = nil
        vehicleStopTask?.cancel()
        vehicleStopTask = nil
        resetVehicleEvidence()
        try await execute()
        try await applyLocationMode(for: powerStateProvider.current)
    }

    private func applyLocationMode(for powerState: PowerState) async throws {
        logPowerStateIfChanged(powerState)
        let mode = desiredLocationMode(for: powerState)
        let monitoringState = await locationProvider.monitoringState
        if appliedLocationMode == nil, monitoringState == .running, mode == .lowPower {
            appliedLocationMode = mode
            lastLoggedModeFailure = nil
            return
        }
        guard appliedLocationMode != mode || monitoringState != .running else {
            lastLoggedModeFailure = nil
            return
        }
        try await locationProvider.setRecordingMode(mode)
        appliedLocationMode = mode
        lastLoggedModeFailure = nil
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

    private func logPowerStateIfChanged(_ powerState: PowerState) {
        guard lastObservedPowerState != powerState else { return }
        lastObservedPowerState = powerState
        logger.info(.powerStateObserved(stateCode: powerState.rawValue))
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

    private struct ModeFailure: Equatable {
        let modeCode: String
        let reasonCode: String
    }
}

private extension StartMonitoringUseCase {
    func startLocationObservationIfNeeded() {
        guard locationObservationTask == nil else { return }
        let locations = locationProvider.locationChanges
        locationObservationTask = Task { [weak self] in
            for await location in locations {
                guard !Task.isCancelled else { return }
                await self?.handleLocationEvidence(location)
            }
        }
    }

    func startActivityObservationIfNeeded() {
        guard activityObservationTask == nil else { return }
        let changes = motionProvider.activityChanges
        activityObservationTask = Task { [weak self] in
            for await event in changes {
                guard !Task.isCancelled else { return }
                await self?.handleActivityChange(event)
            }
        }
    }

    func handleActivityChange(_ event: MotionEventData) async {
        logger.debug(.vehicleActivityObserved(activityCode: activityCode(for: event)))
        guard !isManualHighDensityRecording else { return }
        if event.isAutomotive {
            let previousState = vehicleStateMachine.state
            let state = vehicleStateMachine.observeAutomotiveActivity()
            vehicleStopTask?.cancel()
            vehicleStopTask = nil
            if previousState != .candidate, state == .candidate {
                resetVehicleEvidence()
                scheduleVehicleCandidateTimeout()
            }
            updateVehicleState(state)
            await applyObservedLocationMode(for: powerStateProvider.current)
            return
        }

        let state = vehicleStateMachine.observeNonAutomotiveActivity()
        if state == .idle {
            vehicleCandidateTask?.cancel()
            vehicleCandidateTask = nil
            resetVehicleEvidence()
            updateVehicleState(state)
            await applyObservedLocationMode(for: powerStateProvider.current)
            return
        }
        guard state == .stopping else { return }
        updateVehicleState(state)
        scheduleVehicleStopGracePeriod()
    }

    func handleLocationEvidence(_ location: LocationEventData) async {
        guard vehicleStateMachine.state == .candidate || vehicleStateMachine.state == .stopping else {
            return
        }
        let confirmsMovement = vehicleMovementEvidenceEvaluator.confirmsMovement(
            location, after: lastVehicleEvidenceLocation
        )
        lastVehicleEvidenceLocation = location

        if vehicleStateMachine.state == .stopping, confirmsMovement {
            vehicleStopTask?.cancel()
            vehicleStopTask = nil
            updateVehicleState(vehicleStateMachine.confirmLocationMovement())
            await applyObservedLocationMode(for: powerStateProvider.current)
            return
        }

        guard vehicleStateMachine.state == .candidate else { return }
        vehicleEvidenceCount = confirmsMovement ? vehicleEvidenceCount + 1 : 0
        guard vehicleEvidenceCount >= 2 else { return }
        vehicleCandidateTask?.cancel()
        vehicleCandidateTask = nil
        updateVehicleState(vehicleStateMachine.confirmLocationMovement())
        await applyObservedLocationMode(for: powerStateProvider.current)
    }

    func scheduleVehicleCandidateTimeout() {
        vehicleCandidateTask?.cancel()
        let timeout = vehicleCandidateTimeout
        vehicleCandidateTask = Task { [weak self] in
            do {
                try await Task.sleep(for: timeout)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self?.handleVehicleCandidateTimeout()
        }
    }

    func handleVehicleCandidateTimeout() async {
        guard vehicleStateMachine.state == .candidate else { return }
        updateVehicleState(vehicleStateMachine.expireCandidate())
        resetVehicleEvidence()
        await applyObservedLocationMode(for: powerStateProvider.current)
    }

    func scheduleVehicleStopGracePeriod() {
        vehicleStopTask?.cancel()
        let gracePeriod = vehicleStopGracePeriod
        vehicleStopTask = Task { [weak self] in
            do {
                try await Task.sleep(for: gracePeriod)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self?.handleVehicleStopGracePeriodExpired()
        }
    }

    func handleVehicleStopGracePeriodExpired() async {
        guard vehicleStateMachine.state == .stopping else { return }
        updateVehicleState(vehicleStateMachine.expireStopGracePeriod())
        resetVehicleEvidence()
        await applyObservedLocationMode(for: powerStateProvider.current)
    }

    func resetVehicleEvidence() {
        lastVehicleEvidenceLocation = nil
        vehicleEvidenceCount = 0
    }

    func updateVehicleState(_ state: VehicleRecordingState) {
        guard lastLoggedVehicleState != state else { return }
        lastLoggedVehicleState = state
        logger.info(.vehicleRecordingStateChanged(stateCode: state.rawValue))
    }

    func desiredLocationMode(for powerState: PowerState) -> LocationRecordingMode {
        if isManualHighDensityRecording {
            return .automotiveHighAccuracy
        }
        switch vehicleStateMachine.state {
        case .candidate:
            return .automotiveCandidate
        case .driving, .stopping:
            if powerState.locationRecordingMode == .chargingHighAccuracy {
                return .chargingHighAccuracy
            }
            return .automotiveHighAccuracy
        case .idle:
            return .lowPower
        }
    }

    func activityCode(for event: MotionEventData) -> String {
        if event.isAutomotive {
            return "automotive"
        }
        if event.isStationary {
            return "stationary"
        }
        if event.isWalking {
            return "walking"
        }
        if event.isRunning {
            return "running"
        }
        if event.isCycling {
            return "cycling"
        }
        return "unknown"
    }

    func applyObservedLocationMode(for powerState: PowerState) async {
        do {
            try await applyLocationMode(for: powerState)
        } catch {
            let modeCode = desiredLocationMode(for: powerState).rawValue
            let reasonCode = modeChangeFailureCode(error)
            let failure = ModeFailure(modeCode: modeCode, reasonCode: reasonCode)
            guard lastLoggedModeFailure != failure else { return }
            lastLoggedModeFailure = failure
            logger.error(.locationRecordingModeChangeFailed(
                modeCode: modeCode, reasonCode: reasonCode
            ))
        }
    }
}
