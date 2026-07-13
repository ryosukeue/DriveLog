@testable import DriveLog
import Foundation
import Testing

@Suite("Route encoding")
struct RouteEncodingTests {
    @Test("V1 coordinates round-trip in input order")
    func routeRoundTrips() throws {
        let route = [
            RouteCoordinate(latitude: 35.123_456, longitude: 139.123_456),
            RouteCoordinate(latitude: -33.86, longitude: 151.21)
        ]
        let encoder = PropertyListRouteEncoder()

        #expect(try encoder.decode(encoder.encode(route)) == route)
    }

    @Test("Encoded payload uses binary property list format")
    func usesBinaryPropertyList() throws {
        let data = try PropertyListRouteEncoder().encode([
            RouteCoordinate(latitude: 35, longitude: 139)
        ])

        #expect(data.starts(with: Data("bplist00".utf8)))
    }

    @Test("Empty route round-trips")
    func emptyRouteRoundTrips() throws {
        let encoder = PropertyListRouteEncoder()
        #expect(try encoder.decode(encoder.encode([])).isEmpty)
    }

    @Test("Corrupt data is rejected")
    func rejectsCorruptData() {
        #expect(throws: DriveLogError.invalidData) {
            try PropertyListRouteEncoder().decode(Data([0, 1, 2]))
        }
    }

    @Test("Unknown payload version is rejected")
    func rejectsUnknownVersion() throws {
        let payload = UnknownVersionPayload(formatVersion: 2, coordinates: [])
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(payload)

        #expect(throws: DriveLogError.invalidData) {
            try PropertyListRouteEncoder().decode(data)
        }
    }
}

private struct UnknownVersionPayload: Codable {
    let formatVersion: Int
    let coordinates: [UnknownVersionCoordinate]
}

private struct UnknownVersionCoordinate: Codable {
    let latitude: Double
    let longitude: Double
}
