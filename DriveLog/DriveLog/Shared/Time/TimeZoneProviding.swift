import Foundation

protocol TimeZoneProviding: Sendable {
    var current: TimeZone { get }
}
