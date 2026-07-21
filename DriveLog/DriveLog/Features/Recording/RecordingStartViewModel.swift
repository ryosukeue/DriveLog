import Observation

@MainActor
@Observable
final class RecordingStartViewModel {
    enum State: Equatable {
        case idle
        case starting
        case recording
        case failed
    }

    private(set) var state: State = .idle
    private(set) var errorMessage: String?
    private let startRecording: any RecordingStarting

    init(startRecording: any RecordingStarting) {
        self.startRecording = startRecording
    }

    var startButtonTitle: String {
        switch state {
        case .idle:
            "記録開始"
        case .starting:
            "記録を開始中…"
        case .recording:
            "記録中"
        case .failed:
            "もう一度記録を開始"
        }
    }

    var isStarting: Bool {
        state == .starting
    }

    var isRecording: Bool {
        state == .recording
    }

    func start() async {
        guard state != .starting, state != .recording else { return }
        state = .starting
        errorMessage = nil
        do {
            try await startRecording.startHighDensityRecording()
            state = .recording
        } catch {
            state = .failed
            errorMessage = message(for: error)
        }
    }

    private func message(for error: any Error) -> String {
        switch error {
        case DriveLogError.permissionDenied(.location), DriveLogError.permissionRestricted(.location):
            "位置情報の許可が必要です。設定を確認してください。"
        case DriveLogError.monitoringUnavailable:
            "位置情報を開始できませんでした。時間をおいて再試行してください。"
        default:
            "記録を開始できませんでした。もう一度お試しください。"
        }
    }
}
