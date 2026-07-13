import AVKit
import SwiftUI

struct MediaPreviewView: View {
    @State private var viewModel: MediaPreviewViewModel

    init(viewModel: MediaPreviewViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            content
        }
        .safeAreaInset(edge: .bottom) {
            metadata
        }
        .navigationTitle(viewModel.asset.mediaType == .video ? "動画" : "写真")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("共有", systemImage: "square.and.arrow.up") {
                    Task { await viewModel.share() }
                }
                .disabled(viewModel.canShare == false)
                .accessibilityIdentifier("mediaPreview.share")
            }
        }
        .task {
            guard case .idle = viewModel.state else { return }
            await viewModel.load()
        }
        .onDisappear {
            viewModel.stop()
        }
        .overlay {
            if viewModel.isSharing {
                ProgressView("共有準備中")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("mediaPreview.sharing")
            }
        }
        .alert(
            "共有できませんでした",
            isPresented: Binding(
                get: { viewModel.shareFailed },
                set: {
                    if $0 == false {
                        viewModel.clearShareError()
                    }
                }
            )
        ) {
            Button("OK") { viewModel.clearShareError() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("読み込み中")
                .tint(.white)
                .foregroundStyle(.white)
                .accessibilityIdentifier("mediaPreview.loading")
        case let .photo(image):
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("写真プレビュー")
                .accessibilityIdentifier("mediaPreview.photo")
        case let .video(player):
            VideoPlayer(player: player)
                .accessibilityLabel("動画プレビュー")
                .accessibilityIdentifier("mediaPreview.video")
        case .error:
            VStack(spacing: 12) {
                ContentUnavailableView(
                    "この写真または動画を読み込めません",
                    systemImage: "photo.badge.exclamationmark"
                )
                Button("再試行") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.bordered)
            }
            .foregroundStyle(.white)
            .accessibilityIdentifier("mediaPreview.error")
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let creationDate = viewModel.asset.creationDate {
                Text(creationDate.formatted(date: .abbreviated, time: .shortened))
            }
            if viewModel.asset.location != nil {
                Label("位置情報あり", systemImage: "location.fill")
            }
        }
        .font(.callout)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.black.opacity(0.8))
        .accessibilityIdentifier("mediaPreview.metadata")
    }
}
