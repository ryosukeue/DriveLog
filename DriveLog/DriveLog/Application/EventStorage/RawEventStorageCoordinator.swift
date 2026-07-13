actor RawEventStorageCoordinator {
    private let locationProvider: any LocationProviding
    private let motionProvider: any MotionProviding
    private let visitProvider: any VisitProviding
    private let repository: any RawEventRepository
    private let logger: any Logging
    private var observationTasks: [Task<Void, Never>] = []

    init(
        locationProvider: any LocationProviding,
        motionProvider: any MotionProviding,
        visitProvider: any VisitProviding,
        repository: any RawEventRepository,
        logger: any Logging
    ) {
        self.locationProvider = locationProvider
        self.motionProvider = motionProvider
        self.visitProvider = visitProvider
        self.repository = repository
        self.logger = logger
    }

    deinit {
        observationTasks.forEach { $0.cancel() }
    }

    func start() {
        guard observationTasks.isEmpty else { return }
        let locationEvents = locationProvider.events
        let motionEvents = motionProvider.events
        let visitEvents = visitProvider.events
        observationTasks = [
            Task { [weak self] in
                for await event in locationEvents {
                    guard !Task.isCancelled else { return }
                    await self?.handle(event)
                }
            },
            Task { [weak self] in
                for await event in motionEvents {
                    guard !Task.isCancelled else { return }
                    await self?.handle(event)
                }
            },
            Task { [weak self] in
                for await event in visitEvents {
                    guard !Task.isCancelled else { return }
                    await self?.handle(event)
                }
            }
        ]
    }

    func stop() {
        observationTasks.forEach { $0.cancel() }
        observationTasks.removeAll()
    }

    func isRunning() -> Bool {
        !observationTasks.isEmpty
    }

    private func handle(_ providerEvent: LocationProviderEvent) async {
        switch providerEvent {
        case let .location(event):
            do {
                let result = try await repository.saveLocationEvent(event)
                switch result {
                case .inserted, .updated:
                    logger.info(.locationEventSaved(localDateKey: event.localDateKey))
                case .duplicateIgnored:
                    logger.debug(.locationEventRejected(reasonCode: "duplicate"))
                }
            } catch {
                logger.error(.locationEventRejected(reasonCode: "persistence_failure"))
            }
        case .error:
            logger.error(.locationEventRejected(reasonCode: "provider_error"))
        case .stateChanged:
            break
        }
    }

    private func handle(_ providerEvent: MotionProviderEvent) async {
        guard case let .motion(event) = providerEvent else { return }
        do {
            let result = try await repository.saveMotionEvent(event)
            guard result != .duplicateIgnored else { return }
            logger.info(.motionEventSaved(localDateKey: event.localDateKey))
        } catch {
            return
        }
    }

    private func handle(_ providerEvent: VisitProviderEvent) async {
        guard case let .visit(event) = providerEvent else { return }
        do {
            let result = try await repository.saveOrUpdateVisitEvent(event)
            guard result != .duplicateIgnored else { return }
            logger.info(.visitEventSaved(localDateKey: event.localDateKey))
        } catch {
            return
        }
    }
}
