import Foundation
import SwiftData

@Model
final class MediaAssetCacheModel {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var localIdentifier: String
    var localDateKey: String
    var mediaTypeRawValue: String
    var creationDate: Date?
    var latitude: Double?
    var longitude: Double?
    var durationSeconds: Double?
    var isScreenshot: Bool
    var isScreenRecording: Bool
    var eligibilityRawValue: String
    var lastValidatedAt: Date

    init(
        id: UUID = UUID(), localIdentifier: String, localDateKey: String,
        mediaTypeRawValue: String, creationDate: Date?, latitude: Double?, longitude: Double?,
        durationSeconds: Double?, isScreenshot: Bool, isScreenRecording: Bool,
        eligibilityRawValue: String, lastValidatedAt: Date
    ) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.localDateKey = localDateKey
        self.mediaTypeRawValue = mediaTypeRawValue
        self.creationDate = creationDate
        self.latitude = latitude
        self.longitude = longitude
        self.durationSeconds = durationSeconds
        self.isScreenshot = isScreenshot
        self.isScreenRecording = isScreenRecording
        self.eligibilityRawValue = eligibilityRawValue
        self.lastValidatedAt = lastValidatedAt
    }
}
