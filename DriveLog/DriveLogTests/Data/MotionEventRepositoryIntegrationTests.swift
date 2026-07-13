@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Motion event repository integration")
@MainActor
struct MotionEventRepositoryIntegrationTests {
    @Test("round-trips every flag, confidence, and optional date")
    func roundTripFields() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let savedAt = date.addingTimeInterval(500)
        let repository = SwiftDataRawEventRepository(
            modelContainer: container,
            clock: FixedClock(now: savedAt)
        )
        let events = [
            event(
                seconds: 20, endDate: date.addingTimeInterval(40),
                isAutomotive: true, isWalking: true, isRunning: false,
                isCycling: true, isStationary: false, isUnknown: true,
                confidence: .high
            ),
            event(seconds: 0, confidence: .medium),
            event(seconds: 10, confidence: .low)
        ]

        for event in events {
            #expect(try await repository.saveMotionEvent(event) == .inserted)
        }

        #expect(try await repository.motionEvents(for: key) == [events[1], events[2], events[0]])
        #expect(try processingState(in: container)?.rawRevision == 3)
        #expect(try createdDates(in: container) == [savedAt, savedAt, savedAt])
    }

    @Test("filters events by local date")
    func filterByDate() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let repository = SwiftDataRawEventRepository(
            modelContainer: container,
            clock: FixedClock(now: date)
        )

        #expect(try await repository.saveMotionEvent(event()) == .inserted)
        #expect(
            try await repository.saveMotionEvent(event(localDateKey: "2024-01-02")) == .inserted
        )

        #expect(try await repository.motionEvents(for: key) == [event()])
    }

    private var date: Date {
        Date(timeIntervalSince1970: 1_704_067_200)
    }

    private var key: String {
        "2024-01-01"
    }

    private func event(
        seconds: TimeInterval = 0,
        endDate: Date? = nil,
        isAutomotive: Bool = false,
        isWalking: Bool = false,
        isRunning: Bool = false,
        isCycling: Bool = false,
        isStationary: Bool = false,
        isUnknown: Bool = false,
        confidence: MotionConfidence = .low,
        localDateKey: String = "2024-01-01"
    ) -> MotionEventData {
        MotionEventData(
            startDate: date.addingTimeInterval(seconds), endDate: endDate,
            isAutomotive: isAutomotive, isWalking: isWalking, isRunning: isRunning,
            isCycling: isCycling, isStationary: isStationary, isUnknown: isUnknown,
            confidence: confidence, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: localDateKey
        )
    }

    private func processingState(in container: ModelContainer) throws -> DayProcessingStateModel? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<DayProcessingStateModel>(
            predicate: #Predicate { $0.localDateKey == "2024-01-01" }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func createdDates(in container: ModelContainer) throws -> [Date] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<MotionEventModel>(
            sortBy: [SortDescriptor(\MotionEventModel.startDate)]
        )
        return try context.fetch(descriptor).map(\.createdAt)
    }
}

private struct FixedClock: Clock {
    let now: Date
}
