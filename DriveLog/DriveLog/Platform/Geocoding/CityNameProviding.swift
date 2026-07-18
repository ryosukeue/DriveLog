import Foundation

nonisolated protocol CityNameProviding: Sendable {
    func cityName(for coordinate: RouteCoordinate) async -> String?
}
