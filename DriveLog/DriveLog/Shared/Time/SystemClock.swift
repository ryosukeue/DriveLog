import Foundation

nonisolated struct SystemClock: Clock {
    var now: Date {
        Date()
    }
}
