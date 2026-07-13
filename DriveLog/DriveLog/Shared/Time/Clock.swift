import Foundation

nonisolated protocol Clock: Sendable {
    var now: Date { get }
}
