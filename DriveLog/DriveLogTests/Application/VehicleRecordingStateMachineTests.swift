@testable import DriveLog
import Testing

struct VehicleRecordingStateMachineTests {
    @Test("automotive activity enters driving")
    func automotiveActivity() {
        var machine = VehicleRecordingStateMachine()

        #expect(machine.observeAutomotiveActivity() == .driving)
        #expect(machine.state == .driving)
    }

    @Test("non automotive activity enters stopping without ending recording")
    func nonAutomotiveActivity() {
        var machine = VehicleRecordingStateMachine()
        _ = machine.observeAutomotiveActivity()

        #expect(machine.observeNonAutomotiveActivity() == .stopping)
        #expect(machine.state == .stopping)
    }

    @Test("stop grace expiration returns to idle")
    func stopGraceExpiration() {
        var machine = VehicleRecordingStateMachine()
        _ = machine.observeAutomotiveActivity()
        _ = machine.observeNonAutomotiveActivity()

        #expect(machine.expireStopGracePeriod() == .idle)
        #expect(machine.state == .idle)
    }

    @Test("non automotive activity while idle does not create a stopping state")
    func nonAutomotiveWhileIdle() {
        var machine = VehicleRecordingStateMachine()

        #expect(machine.observeNonAutomotiveActivity() == .idle)
    }
}
