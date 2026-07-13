@testable import DriveLog
import Testing

@Suite("Persistence actor")
struct PersistenceActorTests {
    @Test("In-memory V1 container exposes every model through actor isolation")
    func countsEveryV1Model() async throws {
        let container = try await DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let persistence = PersistenceActor(modelContainer: container)

        #expect(try await persistence.count(LocationEventModel.self) == 0)
        #expect(try await persistence.count(MotionEventModel.self) == 0)
        #expect(try await persistence.count(VisitEventModel.self) == 0)
        #expect(try await persistence.count(DayProcessingStateModel.self) == 0)
        #expect(try await persistence.count(DayAggregateModel.self) == 0)
        #expect(try await persistence.count(MovementSegmentModel.self) == 0)
        #expect(try await persistence.count(StaySegmentModel.self) == 0)
        #expect(try await persistence.count(ClassificationOverrideModel.self) == 0)
        #expect(try await persistence.count(StayOverrideModel.self) == 0)
        #expect(try await persistence.count(MediaAssetCacheModel.self) == 0)
        try await persistence.saveIfNeeded()
    }

    @Test("Concurrent callers complete through the shared actor")
    func serializesConcurrentCallers() async throws {
        let container = try await DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let persistence = PersistenceActor(modelContainer: container)

        let counts = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    try await persistence.count(LocationEventModel.self)
                }
            }

            var values: [Int] = []
            for try await count in group {
                values.append(count)
            }
            return values
        }

        #expect(counts.count == 10)
        #expect(counts.allSatisfy { $0 == 0 })
    }
}
