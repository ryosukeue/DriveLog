import Foundation

protocol RouteEncoding: Sendable {
    func encode(_ coordinates: [RouteCoordinate]) throws -> Data
    func decode(_ data: Data) throws -> [RouteCoordinate]
}
