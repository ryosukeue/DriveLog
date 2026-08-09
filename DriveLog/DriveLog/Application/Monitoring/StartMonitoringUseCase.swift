actor StartMonitoringUseCase {
    private let locationProvider: any LocationProviding
    private let motionProvider: any MotionProviding
    private let visitProvider: any VisitProviding
    private let storageCoordinator: RawEventStorageCoordinator
    private let logger: any Logging
    private var isExecuting = false
    private var appliedLocationMode: LocationRecordingMode?
    private var desiredLocationMode: LocationRecordingMode = .lowPower
    private var hasStarted = false

    init(
        locationProvider: any LocationProviding,
        motionProvider: any MotionProviding,
        visitProvider: any VisitProviding,
        storageCoordinator: RawEventStorageCoordinator,
        logger: any Logging
    ) {
        self.locationProvider = locationProvider
        self.motionProvider = motionProvider
        self.visitProvider = visitProvider
        self.storageCoordinator = storageCoordinator
        self.logger = logger
    }

    func execute() async throws {
        guard !isExecuting else { return }
        isExecuting = true
        defer { isExecuting = false }

        await storageCoordinator.start()
        do {
            try await startSignificantLocationMonitoringIfNeeded()
        } catch {
            await storageCoordinator.stop()
            throw error
        }
        await startMotionIfNeeded()
        await startVisitIfNeeded()
        hasStarted = true
        try? await applyDesiredLocationModeIfNeeded()
    }

    func setVehicleConnected(_ isConnected: Bool) async {
        desiredLocationMode = isConnected ? .vehicleConnected : .lowPower
        guard hasStarted else { return }
        try? await applyDesiredLocationModeIfNeeded()
    }

    private func startSignificantLocationMonitoringIfNeeded() async throws {
        try await applyDesiredLocationModeIfNeeded()
    }

    private func applyDesiredLocationModeIfNeeded() async throws {
        let mode = desiredLocationMode
        let monitoringState = await locationProvider.monitoringState
        if appliedLocationMode == nil, monitoringState == .running {
            appliedLocationMode = mode
            return
        }
        guard appliedLocationMode != mode || monitoringState != .running else { return }
        try await locationProvider.setRecordingMode(mode)
        appliedLocationMode = mode
        logger.info(.locationMonitoringStarted)
        logger.info(.locationRecordingModeChanged(modeCode: mode.rawValue))
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
