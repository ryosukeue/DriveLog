@testable import DriveLog
import Foundation
import Testing

@Suite("Charging location mode")
struct ChargingLocationModeTests {
    @Test("maps only charging states to high accuracy")
    func stateMapping() {
        #expect(PowerState.unknown.locationRecordingMode == .lowPower)
        #expect(PowerState.unplugged.locationRecordingMode == .lowPower)
        #expect(PowerState.charging.locationRecordingMode == .chargingHighAccuracy)
        #expect(PowerState.full.locationRecordingMode == .chargingHighAccuracy)
    }

    @Test("emits immediately then at intervals of at least one minute")
    func emissionInterval() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var filter = ChargingLocationEmissionFilter()

        let first = filter.shouldEmit(start)
        let tooEarly = filter.shouldEmit(start.addingTimeInterval(59.999))
        let boundary = filter.shouldEmit(start.addingTimeInterval(60))
        let secondTooEarly = filter.shouldEmit(start.addingTimeInterval(119))
        let secondBoundary = filter.shouldEmit(start.addingTimeInterval(120))
        #expect(first)
        #expect(!tooEarly)
        #expect(boundary)
        #expect(!secondTooEarly)
        #expect(secondBoundary)

        filter.reset()
        let afterReset = filter.shouldEmit(start.addingTimeInterval(121))
        #expect(afterReset)
    }
}
