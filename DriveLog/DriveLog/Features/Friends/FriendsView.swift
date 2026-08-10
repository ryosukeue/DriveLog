import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct FriendsView: View {
    @State private var viewModel: FriendsViewModel
    @State private var isShowingInvitation = false
    @State private var isShowingICloudSetup = false
    @AppStorage("hasSeenFriendsICloudIntro") private var hasSeenICloudIntro = false
    let iCloudSetupViewModel: ICloudSetupViewModel
    private let distanceFormatter: DistanceFormatter

    init(
        viewModel: FriendsViewModel,
        iCloudSetupViewModel: ICloudSetupViewModel,
        distanceFormatter: DistanceFormatter = DistanceFormatter()
    ) {
        _viewModel = State(initialValue: viewModel)
        self.iCloudSetupViewModel = iCloudSetupViewModel
        self.distanceFormatter = distanceFormatter
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                addFriendButton
                monthSelector
                content
            }
            .padding()
        }
        .navigationTitle("友達")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("iCloud設定", systemImage: "gearshape") {
                    isShowingICloudSetup = true
                }
                .accessibilityIdentifier("friends.icloudSettings")
            }
        }
        .task {
            if !hasSeenICloudIntro, !runsFriendsReviewScreenshot {
                hasSeenICloudIntro = true
                isShowingICloudSetup = true
            }
            guard viewModel.isConnected, viewModel.state == .idle else { return }
            await viewModel.load()
        }
        .sheet(isPresented: $isShowingInvitation) {
            if let invitationURL = viewModel.invitationURL,
               let friendID = viewModel.friendID
            {
                FriendInvitationView(
                    url: invitationURL,
                    friendID: friendID,
                    onAddFriendID: { friendID in
                        await viewModel.acceptFriendID(friendID)
                    }
                )
            } else {
                ProgressView("招待を準備中")
                    .task { await viewModel.prepareInvitation() }
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $isShowingICloudSetup) {
            NavigationStack {
                ICloudSetupView(
                    viewModel: iCloudSetupViewModel,
                    onDismiss: {
                        isShowingICloudSetup = false
                        Task { await viewModel.load() }
                    }
                )
            }
        }
        .alert(
            "友達",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil || viewModel.invitationMessage != nil },
                set: { if !$0 { viewModel.dismissMessages() } }
            )
        ) {
            Button("OK") { viewModel.dismissMessages() }
        } message: {
            Text(viewModel.errorMessage ?? viewModel.invitationMessage ?? "")
        }
        .accessibilityIdentifier("friends.root")
    }

    private var runsFriendsReviewScreenshot: Bool {
        #if DEBUG
            ProcessInfo.processInfo.arguments.contains("-ui-testing-friends-review")
        #else
            false
        #endif
    }

    private var addFriendButton: some View {
        Button {
            isShowingInvitation = true
            Task { await viewModel.prepareInvitation() }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(.blue.opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("友達追加")
                        .font(.headline)
                    Text("QRコードまたはリンクで招待")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("friends.add")
    }

    private var monthSelector: some View {
        HStack {
            Button {
                Task { await viewModel.moveToPreviousMonth() }
            } label: {
                Image(systemName: "chevron.left").frame(width: 36, height: 36)
            }
            Spacer()
            Text(String(viewModel.selectedMonth.year) + "年" + String(viewModel.selectedMonth.month) + "月")
                .monospacedDigit()
                .font(.title2.bold())
            Spacer()
            Button {
                Task { await viewModel.moveToNextMonth() }
            } label: {
                Image(systemName: "chevron.right").frame(width: 36, height: 36)
            }
            .disabled(!viewModel.canMoveToNextMonth)
        }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isConnected {
            ContentUnavailableView {
                Label("iCloud連携が必要です", systemImage: "icloud")
            } description: {
                Text("右上の設定からiCloudに接続すると、月間距離ランキングと友達追加を利用できます。")
            } actions: {
                Button("iCloud設定を開く") { isShowingICloudSetup = true }
            }
            .frame(maxWidth: .infinity, minHeight: 220)
        } else {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("ランキングを更新中")
                    .frame(maxWidth: .infinity, minHeight: 220)
            case .error:
                ContentUnavailableView {
                    Label("ランキングを読み込めませんでした", systemImage: "icloud.slash")
                } actions: {
                    Button("再試行") { Task { await viewModel.load() } }
                }
            case .loaded:
                ranking
            }
        }
    }

    private var ranking: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月間移動距離ランキング")
                .font(.headline)
            ForEach(viewModel.entries) { entry in
                HStack(spacing: 14) {
                    Text("\(entry.rank)")
                        .font(.title3.bold().monospacedDigit())
                        .frame(width: 28)
                        .foregroundStyle(entry.rank <= 3 ? .orange : .secondary)
                    Image(systemName: entry.isCurrentUser ? "person.crop.circle.fill" : "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(entry.isCurrentUser ? .blue : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.displayName + (entry.isCurrentUser ? "（自分）" : ""))
                            .font(.body.weight(.semibold))
                        Text(distanceFormatter.kilometers(
                            fromMeters: entry.distanceMeters
                        ) ?? "0 km")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    entry.isCurrentUser ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
            if viewModel.entries.count == 1 {
                Text("友達を追加すると、ここでその月の距離と順位を競えます。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

private struct FriendInvitationView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    let friendID: String
    let onAddFriendID: (String) async -> String?
    @State private var enteredFriendID = ""
    @State private var isAddingFriend = false
    @State private var resultMessage: String?

    private let appDownloadURL = URL(string: "https://apps.apple.com/app/id6795418978")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("QRコードを読み取るか、友達IDを入力して追加できます。")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    if let qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 260, maxHeight: 260)
                            .padding(16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("友達追加用QRコード")
                    }

                    VStack(spacing: 8) {
                        Text("あなたの友達ID")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(friendID)
                            .font(.title3.bold().monospaced())
                            .textSelection(.enabled)
                        Button("IDをコピー", systemImage: "doc.on.doc") {
                            UIPasteboard.general.string = friendID
                        }
                        .font(.caption)
                    }

                    ShareLink(
                        item: appDownloadURL,
                        subject: Text("ドライブログで友達になろう"),
                        message: Text(friendShareMessage)
                    ) {
                        Label(
                            "IDとダウンロードリンクを共有",
                            systemImage: "square.and.arrow.up"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("友達IDで追加")
                            .font(.headline)
                        TextField("例：AB12-CD34-EF56", text: $enteredFriendID)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                        Button {
                            isAddingFriend = true
                            Task {
                                let error = await onAddFriendID(enteredFriendID)
                                resultMessage = error ?? "友達を追加しました"
                                isAddingFriend = false
                                if error == nil {
                                    enteredFriendID = ""
                                }
                            }
                        } label: {
                            if isAddingFriend {
                                ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Text("IDで友達追加").frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            enteredFriendID.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty || isAddingFriend
                        )
                    }
                }
            }
            .padding(24)
            .navigationTitle("友達追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .alert(
            "友達追加",
            isPresented: Binding(
                get: { resultMessage != nil },
                set: { if !$0 { resultMessage = nil } }
            )
        ) {
            Button("OK") { resultMessage = nil }
        } message: {
            Text(resultMessage ?? "")
        }
    }

    private var friendShareMessage: String {
        """
        ドライブログで友達になろう！

        友達ID：\(friendID)
        """
    }

    private var qrImage: UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let transformed = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext()
        guard let image = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }
        return UIImage(cgImage: image)
    }
}
