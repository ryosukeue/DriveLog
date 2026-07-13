import Foundation
import SwiftData

extension PersistenceActor {
    func saveMotionEvent(
        _ event: MotionEventData,
        createdAt: Date
    ) throws -> RawEventSaveResult {
        modelContext.insert(
            MotionEventModel(
                startDate: event.startDate, endDate: event.endDate,
                isAutomotive: event.isAutomotive, isWalking: event.isWalking,
                isRunning: event.isRunning, isCycling: event.isCycling,
                isStationary: event.isStationary, isUnknown: event.isUnknown,
                confidenceRawValue: Self.rawValue(for: event.confidence),
                createdAt: createdAt, timeZoneIdentifier: event.timeZoneIdentifier,
                utcOffsetSeconds: event.utcOffsetSeconds, localDateKey: event.localDateKey
            )
        )
        try incrementRawRevision(for: event.localDateKey, updatedAt: createdAt)
        try modelContext.save()
        return .inserted
    }

    func motionEvents(for localDateKey: String) throws -> [MotionEventData] {
        let descriptor = FetchDescriptor<MotionEventModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey },
            sortBy: [SortDescriptor(\MotionEventModel.startDate)]
        )
        return try modelContext.fetch(descriptor).map {
            MotionEventData(
                startDate: $0.startDate, endDate: $0.endDate,
                isAutomotive: $0.isAutomotive, isWalking: $0.isWalking,
                isRunning: $0.isRunning, isCycling: $0.isCycling,
                isStationary: $0.isStationary, isUnknown: $0.isUnknown,
                confidence: Self.motionConfidence(from: $0.confidenceRawValue),
                timeZoneIdentifier: $0.timeZoneIdentifier,
                utcOffsetSeconds: $0.utcOffsetSeconds, localDateKey: $0.localDateKey
            )
        }
    }

    private static func rawValue(for confidence: MotionConfidence) -> Int {
        switch confidence {
        case .low: 0
        case .medium: 1
        case .high: 2
        }
    }

    private static func motionConfidence(from rawValue: Int) -> MotionConfidence {
        switch rawValue {
        case 1: .medium
        case 2: .high
        default: .low
        }
    }
}
