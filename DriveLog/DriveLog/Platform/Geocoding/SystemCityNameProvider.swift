import CoreLocation
import Foundation

actor SystemCityNameProvider: CityNameProviding {
    private let geocoder = CLGeocoder()

    func cityName(for coordinate: RouteCoordinate) async -> String? {
        guard !Task.isCancelled,
              coordinate.latitude.isFinite,
              coordinate.longitude.isFinite
        else { return nil }
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        do {
            let placemark = try await geocoder.reverseGeocodeLocation(location).first
            return placemark?.locality ?? placemark?.subAdministrativeArea ??
                placemark?.administrativeArea
        } catch {
            return nil
        }
    }
}
