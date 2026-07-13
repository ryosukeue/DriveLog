@testable import DriveLog
import Foundation
import Testing

@Suite("Day summary data")
struct DaySummaryDataTests {
    @Test("Status and automatic movement cases are distinct")
    func enumCasesAreDistinct() {
        let statuses: [ProcessingStatus] = [.pending, .processing, .completed, .failed]
        let movementTypes: [AutomaticMovementType] = [.automotiveLike, .walkingLike, .other]

        #expect(Set(statuses.map(String.init(describing:))).count == statuses.count)
        #expect(Set(movementTypes.map(String.init(describing:))).count == movementTypes.count)
        requireSendable(statuses)
        requireSendable(movementTypes)
    }

    @Test("Processing state preserves revisions and optional failure details")
    func processingStatePreservesValues() {
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let state = DayProcessingStateData(
            localDateKey: "2023-11-15",
            rawRevision: 4,
            processedRevision: 3,
            status: .failed,
            lastAttemptDate: updatedAt.addingTimeInterval(-10),
            lastSuccessfulDate: nil,
            lastErrorCode: "PERSISTENCE",
            updatedAt: updatedAt
        )

        #expect(state.rawRevision == 4)
        #expect(state.lastSuccessfulDate == nil)
        #expect(state == stateData(status: .failed))
        #expect(state != stateData(status: .pending))
        requireSendable(state)
    }

    @Test("Day aggregate preserves all V1 summary fields")
    func dayAggregatePreservesValues() {
        let aggregate = aggregateData(distance: 1500)

        #expect(aggregate.totalDistanceMeters == 1500)
        #expect(aggregate.automaticClassification == .walkingLike)
        #expect(aggregate.hasValidMovement)
        #expect(aggregate == aggregateData(distance: 1500))
        #expect(aggregate != aggregateData(distance: 1501))
        requireSendable(aggregate)
    }

    @Test("Local month and calendar day preserve display values")
    func monthAndCalendarDayPreserveValues() {
        let month = LocalMonth(year: 2026, month: 7)
        let day = CalendarDayData(
            localDateKey: "2026-07-13",
            day: 13,
            totalDistanceMeters: nil,
            hasValidMovement: false
        )

        #expect(month == LocalMonth(year: 2026, month: 7))
        #expect(month != LocalMonth(year: 2026, month: 8))
        #expect(day.totalDistanceMeters == nil)
        #expect(day != CalendarDayData(
            localDateKey: "2026-07-13",
            day: 13,
            totalDistanceMeters: 1000,
            hasValidMovement: true
        ))
        requireSendable(month)
        requireSendable(day)
    }

    private func stateData(status: ProcessingStatus) -> DayProcessingStateData {
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        return DayProcessingStateData(
            localDateKey: "2023-11-15",
            rawRevision: 4,
            processedRevision: 3,
            status: status,
            lastAttemptDate: updatedAt.addingTimeInterval(-10),
            lastSuccessfulDate: nil,
            lastErrorCode: "PERSISTENCE",
            updatedAt: updatedAt
        )
    }

    private func aggregateData(distance: Double) -> DayAggregateData {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        return DayAggregateData(
            localDateKey: "2023-11-15",
            totalDistanceMeters: distance,
            totalMovementDurationSeconds: 900,
            startDate: start,
            endDate: start.addingTimeInterval(900),
            locationRecordCount: 12,
            rejectedLocationCount: 2,
            mediaCountCache: 3,
            automaticClassification: .walkingLike,
            hasValidMovement: true,
            movementSegmentCount: 2,
            staySegmentCount: 1,
            totalStayDurationSeconds: 300,
            automotiveDurationSeconds: 0,
            walkingDurationSeconds: 900,
            sourceRawRevision: 4,
            generatedAt: start.addingTimeInterval(1000)
        )
    }

    private func requireSendable(_: some Sendable) {}
}
