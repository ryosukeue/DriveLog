@testable import DriveLog
import Testing
import UIKit

@Suite("System power state provider")
@MainActor
struct SystemPowerStateProviderTests {
    @Test("emits an initial snapshot and periodic reconciliation snapshots")
    func initialAndPeriodicSnapshots() async {
        let provider = SystemPowerStateProvider(
            device: .current,
            center: NotificationCenter(),
            reconciliationInterval: .milliseconds(10)
        )
        var iterator = provider.changes.makeAsyncIterator()

        let initial = await iterator.next()
        let periodic = await iterator.next()

        #expect(initial == provider.current)
        #expect(periodic == provider.current)
    }

    @Test("emits a snapshot when the battery notification is observed")
    func notificationSnapshot() async {
        let center = NotificationCenter()
        let provider = SystemPowerStateProvider(
            device: .current,
            center: center,
            reconciliationInterval: .seconds(60)
        )
        var iterator = provider.changes.makeAsyncIterator()
        _ = await iterator.next()

        center.post(name: UIDevice.batteryStateDidChangeNotification, object: nil)
        let notified = await iterator.next()

        #expect(notified == provider.current)
    }
}
