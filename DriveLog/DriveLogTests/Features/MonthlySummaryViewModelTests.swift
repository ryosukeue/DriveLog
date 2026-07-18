@testable import DriveLog
import Testing

@Suite("Monthly summary view model")
@MainActor
struct MonthlySummaryViewModelTests {
    @Test("loads a summary")
    func loads() async {
        let month = LocalMonth(year: 2026, month: 7)
        let summary = MonthlySummaryData(
            month: month, totalDistanceMeters: 1000,
            totalMovementDurationSeconds: 600,
            cityRankings: [CityVisitRanking(cityName: "東京", visitCount: 1)]
        )
        let viewModel = MonthlySummaryViewModel(
            loadMonthlySummary: MonthlySummaryUseCaseFake(result: summary)
        )

        await viewModel.load(month: month)

        #expect(viewModel.state == .loaded)
        #expect(viewModel.summary == summary)
    }

    @Test("represents empty and error states")
    func states() async {
        let month = LocalMonth(year: 2026, month: 7)
        let empty = MonthlySummaryViewModel(
            loadMonthlySummary: MonthlySummaryUseCaseFake(
                result: MonthlySummaryData(
                    month: month, totalDistanceMeters: 0,
                    totalMovementDurationSeconds: 0, cityRankings: []
                )
            )
        )
        await empty.load(month: month)
        #expect(empty.state == .empty)

        let error = MonthlySummaryViewModel(
            loadMonthlySummary: MonthlySummaryUseCaseFake(error: DriveLogError.invalidData)
        )
        await error.load(month: month)
        #expect(error.state == .error)
    }

    @Test("ignores a stale summary response after the month changes")
    func ignoresStaleResponse() async {
        let firstMonth = LocalMonth(year: 2026, month: 7)
        let secondMonth = LocalMonth(year: 2026, month: 8)
        let gate = SummaryGate()
        let viewModel = MonthlySummaryViewModel(
            loadMonthlySummary: GatedMonthlySummaryUseCase(gate: gate, firstMonth: firstMonth)
        )

        let firstLoad = Task { @MainActor in
            await viewModel.load(month: firstMonth)
        }
        await gate.waitUntilFirstRequestStarts()
        await viewModel.load(month: secondMonth)
        await gate.releaseFirstRequest()
        await firstLoad.value

        #expect(viewModel.summary?.month == secondMonth)
    }
}

private struct MonthlySummaryUseCaseFake: LoadMonthlySummaryUseCase {
    let result: MonthlySummaryData?
    let error: (any Error)?

    init(result: MonthlySummaryData? = nil, error: (any Error)? = nil) {
        self.result = result
        self.error = error
    }

    func execute(month: LocalMonth) throws -> MonthlySummaryData {
        if let error {
            throw error
        }
        return result ?? MonthlySummaryData(
            month: month, totalDistanceMeters: 0,
            totalMovementDurationSeconds: 0, cityRankings: []
        )
    }
}

private struct GatedMonthlySummaryUseCase: LoadMonthlySummaryUseCase {
    let gate: SummaryGate
    let firstMonth: LocalMonth

    func execute(month: LocalMonth) async throws -> MonthlySummaryData {
        if month == firstMonth {
            await gate.signalFirstRequestAndWaitForRelease()
        }
        return MonthlySummaryData(
            month: month,
            totalDistanceMeters: month == firstMonth ? 1000 : 2000,
            totalMovementDurationSeconds: 600,
            cityRankings: []
        )
    }
}

private actor SummaryGate {
    private var started: CheckedContinuation<Void, Never>?
    private var released: CheckedContinuation<Void, Never>?

    func waitUntilFirstRequestStarts() async {
        await withCheckedContinuation { continuation in
            started = continuation
        }
    }

    func signalFirstRequestAndWaitForRelease() async {
        started?.resume()
        started = nil
        await withCheckedContinuation { continuation in
            released = continuation
        }
    }

    func releaseFirstRequest() {
        released?.resume()
        released = nil
    }
}
