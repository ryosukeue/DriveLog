import Foundation

struct PropertyListRouteEncoder: RouteEncoding {
    func encode(_ coordinates: [RouteCoordinate]) throws -> Data {
        let payload = EncodedRoutePayloadV1(
            formatVersion: 1,
            coordinates: coordinates.map {
                EncodedCoordinate(latitude: $0.latitude, longitude: $0.longitude)
            }
        )
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary

        do {
            return try encoder.encode(payload)
        } catch {
            throw DriveLogError.invalidData
        }
    }

    func decode(_ data: Data) throws -> [RouteCoordinate] {
        do {
            let payload = try PropertyListDecoder().decode(EncodedRoutePayloadV1.self, from: data)
            guard payload.formatVersion == 1 else {
                throw DriveLogError.invalidData
            }
            return payload.coordinates.map {
                RouteCoordinate(latitude: $0.latitude, longitude: $0.longitude)
            }
        } catch {
            throw DriveLogError.invalidData
        }
    }
}

private struct EncodedRoutePayloadV1: Codable {
    let formatVersion: Int
    let coordinates: [EncodedCoordinate]
}

private struct EncodedCoordinate: Codable {
    let latitude: Double
    let longitude: Double
}
