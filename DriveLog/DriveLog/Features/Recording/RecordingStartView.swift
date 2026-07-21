import SwiftUI

struct RecordingStartView: View {
    @State private var viewModel: RecordingStartViewModel
    private let onBrowseRecords: () -> Void

    init(
        viewModel: RecordingStartViewModel,
        onBrowseRecords: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onBrowseRecords = onBrowseRecords
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: viewModel.isRecording ? "location.fill" : "car.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text(viewModel.isRecording ? "移動を記録しています" : "運転の記録を始める")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text(viewModel.isRecording
                        ? "位置情報を高密度で記録中です"
                        : "出発前にボタンを押してください")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                Button {
                    Task { @MainActor in
                        await viewModel.start()
                    }
                } label: {
                    VStack(spacing: 8) {
                        if viewModel.isStarting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(viewModel.startButtonTitle)
                            .font(.title2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 156)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isStarting || viewModel.isRecording)
                .accessibilityIdentifier("recordingStart.start")
                .accessibilityLabel(viewModel.startButtonTitle)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .accessibilityIdentifier("recordingStart.error")
                }

                Spacer(minLength: max(24, proxy.size.height * 0.16))

                Button("移動記録を参照", systemImage: "calendar") {
                    onBrowseRecords()
                }
                .font(.body.weight(.medium))
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("recordingStart.browse")
                .accessibilityLabel("移動記録を参照")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .accessibilityIdentifier("recordingStart.root")
    }
}
