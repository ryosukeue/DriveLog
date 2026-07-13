import Foundation

nonisolated protocol TimeZoneProviding: Sendable {
    var current: TimeZone { get }
}
