import Foundation
import SwiftData

@Model
final class DayProcessingStateModel {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var localDateKey: String
    var rawRevision: Int
    var processedRevision: Int
    var statusRawValue: String
    var lastAttemptDate: Date?
    var lastSuccessfulDate: Date?
    var lastErrorCode: String?
    var updatedAt: Date

    init(
        id: UUID = UUID(), localDateKey: String, rawRevision: Int, processedRevision: Int,
        statusRawValue: String, lastAttemptDate: Date?, lastSuccessfulDate: Date?,
        lastErrorCode: String?, updatedAt: Date
    ) {
        self.id = id
        self.localDateKey = localDateKey
        self.rawRevision = rawRevision
        self.processedRevision = processedRevision
        self.statusRawValue = statusRawValue
        self.lastAttemptDate = lastAttemptDate
        self.lastSuccessfulDate = lastSuccessfulDate
        self.lastErrorCode = lastErrorCode
        self.updatedAt = updatedAt
    }
}
