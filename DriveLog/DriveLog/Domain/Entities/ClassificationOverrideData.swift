import Foundation

nonisolated struct ClassificationOverrideData: Sendable, Equatable {
    let overrideKey: String
    let targetStableID: String
    let localDateKey: String
    let originalStartDate: Date
    let originalEndDate: Date
    let userClassification: UserMovementClassification
    let createdAt: Date
    let updatedAt: Date
}
