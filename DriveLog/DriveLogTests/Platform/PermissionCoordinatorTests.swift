import CoreLocation
import CoreMotion
@testable import DriveLog
import Photos
import Testing

@Suite("Permission coordinator")
@MainActor
struct PermissionCoordinatorTests {
    @Test("maps every location authorization state")
    func locationMapping() {
        #expect(PermissionCoordinator.locationState(.notDetermined) == .notDetermined)
        #expect(PermissionCoordinator.locationState(.restricted) == .restricted)
        #expect(PermissionCoordinator.locationState(.denied) == .denied)
        #expect(PermissionCoordinator.locationState(.authorizedWhenInUse) == .whenInUse)
        #expect(PermissionCoordinator.locationState(.authorizedAlways) == .always)
    }

    @Test("maps every motion authorization state")
    func motionMapping() {
        #expect(PermissionCoordinator.motionState(.notDetermined) == .notDetermined)
        #expect(PermissionCoordinator.motionState(.restricted) == .restricted)
        #expect(PermissionCoordinator.motionState(.denied) == .denied)
        #expect(PermissionCoordinator.motionState(.authorized) == .authorized)
    }

    @Test("maps every photo authorization state including limited")
    func photoMapping() {
        #expect(PermissionCoordinator.photoState(.notDetermined) == .notDetermined)
        #expect(PermissionCoordinator.photoState(.restricted) == .restricted)
        #expect(PermissionCoordinator.photoState(.denied) == .denied)
        #expect(PermissionCoordinator.photoState(.limited) == .limited)
        #expect(PermissionCoordinator.photoState(.authorized) == .authorized)
    }

    @Test("refresh emits only changed aggregate state")
    func refresh() async {
        let system = FakePermissionSystemAccess()
        let coordinator = PermissionCoordinator(system: system)
        var iterator = coordinator.updates.makeAsyncIterator()
        system.locationStatus = .authorizedWhenInUse
        await coordinator.refresh()
        #expect(await iterator.next()?.location == .whenInUse)
        #expect(coordinator.currentState.photos == .notDetermined)
    }

    @Test("system changes update the stream and requests reach the system boundary")
    func systemUpdatesAndRequests() async {
        let system = FakePermissionSystemAccess()
        let coordinator = PermissionCoordinator(system: system)
        var iterator = coordinator.updates.makeAsyncIterator()
        system.photoStatus = .limited
        system.sendAuthorizationChange()
        #expect(await iterator.next()?.photos == .limited)

        await coordinator.requestLocationWhenInUse()
        await coordinator.requestLocationAlways()
        await coordinator.requestMotion()
        await coordinator.requestPhotos()
        coordinator.openSystemSettings()
        #expect(system.locationWhenInUseRequestCount == 1)
        #expect(system.locationAlwaysRequestCount == 1)
        #expect(system.motionRequestCount == 1)
        #expect(system.photosRequestCount == 1)
        #expect(system.openSettingsCount == 1)
    }

    @Test("fake streams states and records every request")
    func fake() async {
        let fake = FakePermissionManager(state: undeterminedState)
        var iterator = fake.updates.makeAsyncIterator()
        let updated = PermissionState(location: .always, motion: .denied, photos: .limited)
        fake.send(updated)
        #expect(await iterator.next() == updated)
        await fake.refresh()
        await fake.requestLocationWhenInUse()
        await fake.requestLocationAlways()
        await fake.requestMotion()
        await fake.requestPhotos()
        fake.openSystemSettings()
        #expect(fake.refreshCount == 1)
        #expect(fake.locationWhenInUseRequestCount == 1)
        #expect(fake.locationAlwaysRequestCount == 1)
        #expect(fake.motionRequestCount == 1)
        #expect(fake.photosRequestCount == 1)
        #expect(fake.openSettingsCount == 1)
    }

    private var undeterminedState: PermissionState {
        PermissionState(location: .notDetermined, motion: .notDetermined, photos: .notDetermined)
    }
}

@MainActor
private final class FakePermissionSystemAccess: PermissionSystemAccessing {
    nonisolated let authorizationChanges: AsyncStream<Void>
    var locationStatus: CLAuthorizationStatus = .notDetermined
    var motionStatus: CMAuthorizationStatus = .notDetermined
    var photoStatus: PHAuthorizationStatus = .notDetermined
    private(set) var locationWhenInUseRequestCount = 0
    private(set) var locationAlwaysRequestCount = 0
    private(set) var motionRequestCount = 0
    private(set) var photosRequestCount = 0
    private(set) var openSettingsCount = 0

    private let continuation: AsyncStream<Void>.Continuation

    init() {
        let stream = AsyncStream.makeStream(of: Void.self)
        authorizationChanges = stream.stream
        continuation = stream.continuation
    }

    func requestLocationWhenInUse() {
        locationWhenInUseRequestCount += 1
    }

    func requestLocationAlways() {
        locationAlwaysRequestCount += 1
    }

    func requestMotion() {
        motionRequestCount += 1
    }

    func requestPhotos() async {
        photosRequestCount += 1
    }

    func openSystemSettings() {
        openSettingsCount += 1
    }

    func sendAuthorizationChange() {
        continuation.yield(())
    }
}
