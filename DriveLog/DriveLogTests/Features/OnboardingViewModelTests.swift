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

        #expect(await viewModel.performPrimaryAction() == false)
        #expect(permissions.locationWhenInUseRequestCount == 1)
        #expect(permissions.locationAlwaysRequestCount == 0)

        permissions.send(state(location: .whenInUse))
        await waitUntil { viewModel.permissionState.location == .whenInUse }
        #expect(await viewModel.performPrimaryAction() == false)
        #expect(permissions.locationAlwaysRequestCount == 1)
        observation.cancel()
    }

    @Test("location terminal states advance to motion without another location request")
    func terminalStates() async {
        for location in [LocationPermissionState.always, .denied, .restricted] {
            let permissions = FakePermissionManager(state: state(location: location))
            let viewModel = OnboardingViewModel(permissionManager: permissions)

            #expect(await viewModel.performPrimaryAction() == false)
            #expect(viewModel.phase == .motion)
            #expect(permissions.locationWhenInUseRequestCount == 0)
            #expect(permissions.locationAlwaysRequestCount == 0)
        }
    }

    @Test("requests motion once and completes for terminal motion states")
    func motion() async {
        let permissions = FakePermissionManager(state: state(location: .always))
        let viewModel = OnboardingViewModel(permissionManager: permissions)
        #expect(await viewModel.performPrimaryAction() == false)

        #expect(await viewModel.performPrimaryAction() == false)
        #expect(permissions.motionRequestCount == 1)

        for motion in [MotionPermissionState.authorized, .denied, .restricted] {
            let terminal = FakePermissionManager(state: PermissionState(
                location: .always,
                motion: motion,
                photos: .notDetermined
            ))
            let terminalViewModel = OnboardingViewModel(permissionManager: terminal)
            #expect(await terminalViewModel.performPrimaryAction() == false)
            #expect(await terminalViewModel.performPrimaryAction() == false)
            #expect(terminalViewModel.phase == .photos)
            #expect(terminal.motionRequestCount == 0)
        }
    }

    @Test("requests photos last and completes for every terminal photo state")
    func photos() async {
        let permissions = FakePermissionManager(state: PermissionState(
            location: .always,
            motion: .authorized,
            photos: .notDetermined
        ))
        let viewModel = OnboardingViewModel(permissionManager: permissions)
        #expect(await viewModel.performPrimaryAction() == false)
        #expect(await viewModel.performPrimaryAction() == false)
        #expect(viewModel.phase == .photos)
        #expect(await viewModel.performPrimaryAction() == false)
        #expect(permissions.photosRequestCount == 1)

        for photos in [
            PhotoPermissionState.authorized, .limited, .denied, .restricted
        ] {
            let terminal = FakePermissionManager(state: PermissionState(
                location: .always,
                motion: .authorized,
                photos: photos
            ))
            let terminalViewModel = OnboardingViewModel(permissionManager: terminal)
            #expect(await terminalViewModel.performPrimaryAction() == false)
            #expect(await terminalViewModel.performPrimaryAction() == false)
            #expect(await terminalViewModel.performPrimaryAction())
            #expect(terminal.photosRequestCount == 0)
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
