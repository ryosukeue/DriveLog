import Foundation

protocol LocalTimeContextProviding: Sendable {
    func makeContext(for date: Date) -> RecordedTimeContext
}
