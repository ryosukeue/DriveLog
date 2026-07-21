@testable import DriveLog
import Testing

struct VehicleRecordingStateMachineTests {
    @Test("automotive activity enters candidate")
    func automotiveActivity() {
        var machine = VehicleRecordingStateMachine()

        #expect(machine.observeAutomotiveActivity() == .candidate)
        #expect(machine.state == .candidate)
    }

    @Test("location movement confirms driving")
    func locationMovementConfirmsDriving() {
        var machine = VehicleRecordingStateMachine()
        _ = machine.observeAutomotiveActivity()

        #expect(machine.confirmLocationMovement() == .driving)
        #expect(machine.state == .driving)
    }

    @Test("non automotive activity enters stopping without ending recording")
    func nonAutomotiveActivity() {
        var machine = VehicleRecordingStateMachine()
        _ = machine.observeAutomotiveActivity()
        _ = machine.confirmLocationMovement()

        #expect(machine.observeNonAutomotiveActivity() == .stopping)
        #expect(machine.state == .stopping)
    }

    @Test("stop grace expiration returns to idle")
    func stopGraceExpiration() {
        var machine = VehicleRecordingStateMachine()
        _ = machine.observeAutomotiveActivity()
        _ = machine.confirmLocationMovement()
        _ = machine.observeNonAutomotiveActivity()

        #expect(machine.expireStopGracePeriod() == .idle)
        #expect(machine.state == .idle)
    }

    @Test("non automotive activity while idle does not create a stopping state")
    func nonAutomotiveWhileIdle() {
        var machine = VehicleRecordingStateMachine()

        #expect(machine.observeNonAutomotiveActivity() == .idle)
    }

    @Test("candidate expires without location movement")
    func candidateExpiration() {
        var machine = VehicleRecordingStateMachine()
        _ = machine.observeAutomotiveActivity()

        #expect(machine.expireCandidate() == .idle)
        #expect(machine.state == .idle)
    }
}
