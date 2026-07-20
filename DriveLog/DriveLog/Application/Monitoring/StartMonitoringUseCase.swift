actor StartMonitoringUseCase {
    private let locationProvider: any LocationProviding
    private let motionProvider: any MotionProviding
    private let visitProvider: any VisitProviding
    private let storageCoordinator: RawEventStorageCoordinator
    private let powerStateProvider: any PowerStateProviding
    private let logger: any Logging
    private var isExecuting = false
    private var powerObservationTask: Task<Void, Never>?
    private var activityObservationTask: Task<Void, Never>?
    private var vehicleStopTask: Task<Void, Never>?
    private var appliedLocationMode: LocationRecordingMode?
    private var lastObservedPowerState: PowerState?
    private var lastLoggedModeFailure: ModeFailure?
    private var lastLoggedVehicleState: VehicleRecordingState?
    private var vehicleStateMachine = VehicleRecordingStateMachine()
    private let vehicleStopGracePeriod: Duration

    init(
        locationProvider: any LocationProviding,
        motionProvider: any MotionProviding,
        visitProvider: any VisitProviding,
        storageCoordinator: RawEventStorageCoordinator,
        powerStateProvider: any PowerStateProviding,
        logger: any Logging,
        vehicleStopGracePeriod: Duration = .seconds(180)
    ) {
        self.locationProvider = locationProvider
        self.motionProvider = motionProvider
        self.visitProvider = visitProvider
        self.storageCoordinator = storageCoordinator
        self.powerStateProvider = powerStateProvider
        self.logger = logger
        self.vehicleStopGracePeriod = vehicleStopGracePeriod
    }

    deinit {
        powerObservationTask?.cancel()
        activityObservationTask?.cancel()
        vehicleStopTask?.cancel()
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
        startActivityObservationIfNeeded()
        await startVisitIfNeeded()
        startPowerObservationIfNeeded()
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

    private func startActivityObservationIfNeeded() {
        guard activityObservationTask == nil else { return }
        let changes = motionProvider.activityChanges
        activityObservationTask = Task { [weak self] in
            for await event in changes {
                guard !Task.isCancelled else { return }
                await self?.handleActivityChange(event)
            }
        }
    }

    private func handleActivityChange(_ event: MotionEventData) async {
        logger.debug(.vehicleActivityObserved(activityCode: activityCode(for: event)))
        if event.isAutomotive {
            vehicleStopTask?.cancel()
            vehicleStopTask = nil
            updateVehicleState(vehicleStateMachine.observeAutomotiveActivity())
            await applyObservedLocationMode(for: powerStateProvider.current)
            return
        }

        let state = vehicleStateMachine.observeNonAutomotiveActivity()
        guard state == .stopping else { return }
        updateVehicleState(state)
        scheduleVehicleStopGracePeriod()
    }

    private func scheduleVehicleStopGracePeriod() {
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

    private func handleVehicleStopGracePeriodExpired() async {
        guard vehicleStateMachine.state == .stopping else { return }
        updateVehicleState(vehicleStateMachine.expireStopGracePeriod())
        await applyObservedLocationMode(for: powerStateProvider.current)
    }

    private func updateVehicleState(_ state: VehicleRecordingState) {
        guard lastLoggedVehicleState != state else { return }
        lastLoggedVehicleState = state
        logger.info(.vehicleRecordingStateChanged(stateCode: state.rawValue))
    }

    private func desiredLocationMode(for powerState: PowerState) -> LocationRecordingMode {
        if powerState.locationRecordingMode == .chargingHighAccuracy {
            return .chargingHighAccuracy
        }
        if vehicleStateMachine.state != .idle {
            return .automotiveHighAccuracy
        }
        return .lowPower
    }

    private func activityCode(for event: MotionEventData) -> String {
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

    private func applyObservedLocationMode(for powerState: PowerState) async {
        do {
            try await applyLocationMode(for: powerState)
        } catch {
            let modeCode = powerState.locationRecordingMode.rawValue
            let reasonCode = modeChangeFailureCode(error)
            let failure = ModeFailure(modeCode: modeCode, reasonCode: reasonCode)
            guard lastLoggedModeFailure != failure else { return }
            lastLoggedModeFailure = failure
            logger.error(.locationRecordingModeChangeFailed(
                modeCode: modeCode, reasonCode: reasonCode
            ))
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
