@testable import DriveLog
import Foundation
import Testing

@Suite("Monthly overview view model")
@MainActor
struct MonthlyOverviewViewModelTests {
    @Test("loads a non-empty overview")
    func loads() async {
        let month = LocalMonth(year: 2026, month: 7)
        let overview = MonthlyOverviewData(
            month: month, mapScene: .empty,
            movements: [movement()], stays: [], media: []
        )
        let viewModel = MonthlyOverviewViewModel(
            loadMonthlyOverview: MonthlyOverviewUseCaseFake(result: overview)
        )

        await viewModel.load(month: month)

        #expect(viewModel.state == .loaded)
        #expect(viewModel.overview == overview)
    }

    @Test("represents empty and failed states")
    func states() async {
        let month = LocalMonth(year: 2026, month: 7)
        let empty = MonthlyOverviewViewModel(
            loadMonthlyOverview: MonthlyOverviewUseCaseFake(
                result: MonthlyOverviewData(
                    month: month, mapScene: .empty,
                    movements: [], stays: [], media: []
                )
            )
        )
        await empty.load(month: month)
        #expect(empty.state == .empty)

        let failed = MonthlyOverviewViewModel(
            loadMonthlyOverview: MonthlyOverviewUseCaseFake(error: DriveLogError.invalidData)
        )
        await failed.load(month: month)
        #expect(failed.state == .error)
    }

    private func movement() -> MovementSegmentData {
        MovementSegmentData(
            stableID: "car", localDateKey: "2026-07-01",
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 600), distanceMeters: 1000,
            durationSeconds: 600, estimatedAverageSpeedMetersPerSecond: 10,
            automaticClassification: .automotiveLike, classificationConfidence: .medium,
            route: [], labelCoordinate: nil, sourceRawRevision: 1,
            generatedAt: Date(timeIntervalSince1970: 0)
        )
    }
}

private struct MonthlyOverviewUseCaseFake: LoadMonthlyOverviewUseCase {
    let result: MonthlyOverviewData?
    let error: (any Error)?

    init(result: MonthlyOverviewData? = nil, error: (any Error)? = nil) {
        self.result = result
        self.error = error
    }

    func execute(month: LocalMonth) throws -> MonthlyOverviewData {
        if let error {
            throw error
        }
        return result ?? MonthlyOverviewData(
            month: month, mapScene: .empty,
            movements: [], stays: [], media: []
        )
    }
}
