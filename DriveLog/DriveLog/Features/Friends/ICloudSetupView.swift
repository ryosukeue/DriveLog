import SwiftUI

struct ICloudSetupView: View {
    @State private var viewModel: ICloudSetupViewModel
    let onCompleted: () -> Void

    init(viewModel: ICloudSetupViewModel, onCompleted: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onCompleted = onCompleted
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "icloud.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            VStack(spacing: 10) {
                Text("iCloudと連携")
                    .font(.largeTitle.bold())
                Text(
                    "友達との月間距離バトルと招待にiCloudを使います。" +
                        "移動経路や写真は友達には共有されません。"
                )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            TextField("ランキングに表示する名前", text: $viewModel.displayName)
                .textFieldStyle(.roundedBorder)
                .textContentType(.nickname)
            statusMessage
            Button {
                Task {
                    if await viewModel.connect() {
                        onCompleted()
                    }
                }
            } label: {
                if viewModel.isConnecting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("iCloudに接続")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.status != .available || viewModel.isConnecting)
            if viewModel.status != .available && viewModel.status != .checking {
                Button("再確認") {
                    Task { await viewModel.check() }
                }
            }
            Button("あとで") {
                onCompleted()
            }
            .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(28)
        .task {
            await viewModel.check()
        }
        .alert(
            "iCloud連携",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .accessibilityIdentifier("icloud.setup")
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch viewModel.status {
        case .idle, .checking:
            ProgressView("iCloudアカウントを確認中")
        case .available:
            Label("iCloudを利用できます", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .noAccount:
            Label(
                "設定からiCloudにサインインしてください",
                systemImage: "person.crop.circle.badge.exclamationmark"
            )
                .foregroundStyle(.secondary)
        case .restricted:
            Label("この端末ではiCloudの利用が制限されています", systemImage: "lock.fill")
                .foregroundStyle(.secondary)
        case .temporarilyUnavailable:
            Label("iCloudの状態を確認できません", systemImage: "exclamationmark.icloud")
                .foregroundStyle(.secondary)
        }
    }
}
