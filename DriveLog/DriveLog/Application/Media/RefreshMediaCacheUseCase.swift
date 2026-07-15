import Foundation

nonisolated protocol RefreshMediaCacheUseCase: Sendable {
    func execute(localDateKey: String) async throws -> [MediaAssetReference]
}

nonisolated struct DefaultRefreshMediaCacheUseCase: RefreshMediaCacheUseCase {
    private let photoLibrary: any PhotoLibraryProviding
    private let eligibilityEvaluator: any MediaEligibilityEvaluating
    private let mediaCacheRepository: any MediaCacheRepository
    private let clock: any Clock
    private let timeZoneProvider: any TimeZoneProviding
    private let logger: any Logging

    init(
        photoLibrary: any PhotoLibraryProviding,
        eligibilityEvaluator: any MediaEligibilityEvaluating,
        mediaCacheRepository: any MediaCacheRepository,
        clock: any Clock,
        timeZoneProvider: any TimeZoneProviding,
        logger: any Logging
    ) {
        self.photoLibrary = photoLibrary
        self.eligibilityEvaluator = eligibilityEvaluator
        self.mediaCacheRepository = mediaCacheRepository
        self.clock = clock
        self.timeZoneProvider = timeZoneProvider
        self.logger = logger
    }

    func execute(localDateKey: String) async throws -> [MediaAssetReference] {
        let authorization = await photoLibrary.authorizationState()
        let interval = try dateInterval(
            for: localDateKey,
            timeZone: timeZoneProvider.current
        )
        let fetched = try await photoLibrary.fetchAssets(in: interval)
        let eligible = fetched
            .filter { eligibilityEvaluator.evaluate($0) == .eligible }
            .sorted(by: assetOrder)
        logger.info(.mediaPlacementDiagnosed(
            permissionCode: authorization.diagnosticCode,
            fetchedCount: fetched.count,
            eligibleCount: eligible.count,
            locatedCount: eligible.count { $0.location != nil }
        ))
        try await mediaCacheRepository.replaceAssets(
            for: localDateKey,
            assets: eligible,
            validatedAt: clock.now
        )
        logger.info(.mediaCacheRefreshed(localDateKey: localDateKey, count: eligible.count))
        return eligible
    }

    private func dateInterval(for localDateKey: String, timeZone: TimeZone) throws -> DateInterval {
        let parts = localDateKey.split(separator: "-", omittingEmptySubsequences: false)
        guard localDateKey.count == 10,
              localDateKey[localDateKey.index(localDateKey.startIndex, offsetBy: 4)] == "-",
              localDateKey[localDateKey.index(localDateKey.startIndex, offsetBy: 7)] == "-",
              parts.count == 3,
              parts[0].count == 4,
              parts[1].count == 2,
              parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { throw DriveLogError.invalidData }

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        guard let start = calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: year,
            month: month,
            day: day
        )),
            calendar.component(.year, from: start) == year,
            calendar.component(.month, from: start) == month,
            calendar.component(.day, from: start) == day,
            let end = calendar.date(byAdding: .day, value: 1, to: start)
        else { throw DriveLogError.invalidData }

        return DateInterval(start: start, end: end)
    }

    private func assetOrder(_ first: MediaAssetReference, _ second: MediaAssetReference) -> Bool {
        guard first.creationDate == second.creationDate else {
            return (first.creationDate ?? .distantFuture) < (second.creationDate ?? .distantFuture)
        }
        return first.localIdentifier < second.localIdentifier
    }
}

private extension PhotoPermissionState {
    nonisolated var diagnosticCode: String {
        switch self {
        case .notDetermined: "not_determined"
        case .restricted: "restricted"
        case .denied: "denied"
        case .limited: "limited"
        case .authorized: "authorized"
        }
    }
}
