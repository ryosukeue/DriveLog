import Foundation

struct SystemTimeZoneProvider: TimeZoneProviding {
    var current: TimeZone {
        TimeZone.current
    }
}
