import Foundation

nonisolated struct GeodesicDistanceCalculator: Sendable {
    func meters(
        fromLatitude startLatitudeDegrees: Double,
        longitude startLongitudeDegrees: Double,
        toLatitude endLatitudeDegrees: Double,
        longitude endLongitudeDegrees: Double
    ) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let latitudeDelta = radians(endLatitudeDegrees - startLatitudeDegrees)
        let longitudeDelta = radians(endLongitudeDegrees - startLongitudeDegrees)
        let startLatitude = radians(startLatitudeDegrees)
        let endLatitude = radians(endLatitudeDegrees)
        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2) +
            cos(startLatitude) * cos(endLatitude) *
            sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return 2 * earthRadiusMeters * atan2(sqrt(haversine), sqrt(max(0, 1 - haversine)))
    }

    private func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
