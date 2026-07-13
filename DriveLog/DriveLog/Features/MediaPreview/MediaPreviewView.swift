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
        .navigationTitle("写真")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("共有", systemImage: "square.and.arrow.up") {}
                    .disabled(viewModel.canShare == false)
                    .accessibilityIdentifier("mediaPreview.share")
            }
        }
        .task {
            guard case .idle = viewModel.state else { return }
            await viewModel.load()
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
