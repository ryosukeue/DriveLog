@testable import DriveLog
import Foundation
import Testing

@Suite("Distance formatter")
struct DistanceFormatterTests {
    @Test("formats meters as one-decimal kilometers")
    func kilometers() {
        let formatter = DistanceFormatter(locale: Locale(identifier: "en_US"))

        #expect(formatter.kilometers(fromMeters: 1000) == "1.0km")
        #expect(formatter.kilometers(fromMeters: 18400) == "18.4km")
    }

    @Test("uses the locale decimal separator")
    func locale() {
        let formatter = DistanceFormatter(locale: Locale(identifier: "de_DE"))

        #expect(formatter.kilometers(fromMeters: 1500) == "1,5km")
    }

    @Test("rejects invalid distances")
    func invalid() {
        let formatter = DistanceFormatter(locale: Locale(identifier: "en_US"))

        #expect(formatter.kilometers(fromMeters: -.infinity) == nil)
        #expect(formatter.kilometers(fromMeters: .infinity) == nil)
        #expect(formatter.kilometers(fromMeters: .nan) == nil)
        #expect(formatter.kilometers(fromMeters: -1) == nil)
    }
}
