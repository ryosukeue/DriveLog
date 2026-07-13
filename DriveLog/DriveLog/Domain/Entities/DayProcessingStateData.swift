import Foundation

struct DayProcessingStateData: Sendable, Equatable {
    let localDateKey: String
    let rawRevision: Int
    let processedRevision: Int
    let status: ProcessingStatus
    let lastAttemptDate: Date?
    let lastSuccessfulDate: Date?
    let lastErrorCode: String?
    let updatedAt: Date
}
