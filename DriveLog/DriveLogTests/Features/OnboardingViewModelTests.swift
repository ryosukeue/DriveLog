@testable import DriveLog
import Testing

@MainActor
@Suite("Onboarding view model")
struct OnboardingViewModelTests {
    @Test("requests location in use before always")
    func stagedLocation() async {
        let permissions = FakePermissionManager(state: state(location: .notDetermined))
        let viewModel = OnboardingViewModel(permissionManager: permissions)
        let observation = Task { await viewModel.observePermissionUpdates() }

        #expect(await viewModel.performLocationAction() == false)
        #expect(permissions.locationWhenInUseRequestCount == 1)
        #expect(permissions.locationAlwaysRequestCount == 0)

        permissions.send(state(location: .whenInUse))
        await waitUntil { viewModel.permissionState.location == .whenInUse }
        #expect(await viewModel.performLocationAction() == false)
        #expect(permissions.locationAlwaysRequestCount == 1)
        observation.cancel()
    }

    @Test("continues without another request for terminal states")
    func terminalStates() async {
        for location in [LocationPermissionState.always, .denied, .restricted] {
            let permissions = FakePermissionManager(state: state(location: location))
            let viewModel = OnboardingViewModel(permissionManager: permissions)

            #expect(await viewModel.performLocationAction())
            #expect(permissions.locationWhenInUseRequestCount == 0)
            #expect(permissions.locationAlwaysRequestCount == 0)
        }
    }

    private func state(location: LocationPermissionState) -> PermissionState {
        PermissionState(location: location, motion: .notDetermined, photos: .notDetermined)
    }
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0 ..< 100 {
        if condition() {
            return
        }
        await Task.yield()
    }
}
