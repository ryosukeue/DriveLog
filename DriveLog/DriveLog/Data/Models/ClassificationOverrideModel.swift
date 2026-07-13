import Foundation
import SwiftData

@Model
final class ClassificationOverrideModel {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var overrideKey: String
    var targetStableID: String
    var localDateKey: String
    var originalStartDate: Date
    var originalEndDate: Date
    var userClassificationRawValue: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(), overrideKey: String, targetStableID: String,
        localDateKey: String, originalStartDate: Date, originalEndDate: Date,
        userClassificationRawValue: String, createdAt: Date, updatedAt: Date
    ) {
        self.id = id
        self.overrideKey = overrideKey
        self.targetStableID = targetStableID
        self.localDateKey = localDateKey
        self.originalStartDate = originalStartDate
        self.originalEndDate = originalEndDate
        self.userClassificationRawValue = userClassificationRawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
