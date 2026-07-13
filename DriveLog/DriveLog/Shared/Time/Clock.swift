import Foundation

protocol Clock: Sendable {
    var now: Date { get }
}
