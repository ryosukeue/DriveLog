@testable import DriveLog
import os
import Testing

@MainActor
@Suite("Recording start view model")
struct RecordingStartViewModelTests {
    @Test("starts high density recording and reports recording state")
    func startsRecording() async {
        let starter = RecordingStarterFake()
        let viewModel = RecordingStartViewModel(startRecording: starter)

        await viewModel.start()

        #expect(viewModel.state == .recording)
        #expect(viewModel.errorMessage == nil)
        #expect(starter.callCount == 1)
    }

    @Test("keeps a retryable error state when starting fails")
    func reportsFailure() async {
        let starter = RecordingStarterFake(error: .monitoringUnavailable)
        let viewModel = RecordingStartViewModel(startRecording: starter)

        await viewModel.start()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage != nil)
        #expect(starter.callCount == 1)
    }

    @Test("ignores duplicate starts while recording")
    func ignoresDuplicateStart() async {
        let starter = RecordingStarterFake()
        let viewModel = RecordingStartViewModel(startRecording: starter)

        await viewModel.start()
        await viewModel.start()

        #expect(viewModel.state == .recording)
        #expect(starter.callCount == 1)
    }
}

private final class RecordingStarterFake: RecordingStarting, @unchecked Sendable {
    private let storage = OSAllocatedUnfairLock(initialState: (count: 0, error: DriveLogError?.none))

    var callCount: Int {
        storage.withLock(\.count)
    }

    private var error: DriveLogError? {
        storage.withLock(\.error)
    }

    init(error: DriveLogError? = nil) {
        storage.withLock { $0.error = error }
    }

    func startHighDensityRecording() async throws {
        storage.withLock { state in
            state.count += 1
        }
        if let error {
            throw error
        }
    }
}
