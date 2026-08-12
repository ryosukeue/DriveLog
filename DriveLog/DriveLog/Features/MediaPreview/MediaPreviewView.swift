import AVKit
import SwiftUI

struct MediaPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModels: [MediaPreviewViewModel]
    @State private var selectedIdentifier: String

    init(viewModel: MediaPreviewViewModel) {
        self.init(viewModels: [viewModel], selectedIdentifier: viewModel.asset.localIdentifier)
    }

    init(
        viewModels: [MediaPreviewViewModel],
        selectedIdentifier: String
    ) {
        let initialIdentifier = viewModels.contains {
            $0.asset.localIdentifier == selectedIdentifier
        } ? selectedIdentifier : viewModels.first?.asset.localIdentifier ?? ""
        _viewModels = State(initialValue: viewModels)
        _selectedIdentifier = State(initialValue: initialIdentifier)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $selectedIdentifier) {
                ForEach(viewModels, id: \.asset.localIdentifier) { viewModel in
                    MediaPreviewPage(
                        viewModel: viewModel,
                        isSelected: viewModel.asset.localIdentifier == selectedIdentifier
                    )
                        .tag(viewModel.asset.localIdentifier)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("戻る")
                .accessibilityIdentifier("mediaPreview.back")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("共有", systemImage: "square.and.arrow.up") {
                    guard let selectedViewModel else { return }
                    Task { await selectedViewModel.share() }
                }
                .disabled(selectedViewModel?.canShare != true)
                .accessibilityIdentifier("mediaPreview.share")
            }
        }
        .overlay {
            if selectedViewModel?.isSharing == true {
                ProgressView("共有準備中")
                    .padding()
                    .driveLogGlassEffect(in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("mediaPreview.sharing")
            }
        }
        .alert("共有できませんでした", isPresented: shareErrorBinding) {
            Button("OK") { selectedViewModel?.clearShareError() }
        }
        .onChange(of: selectedIdentifier) { oldValue, _ in
            viewModels.first { $0.asset.localIdentifier == oldValue }?.stop()
        }
    }

    private var selectedViewModel: MediaPreviewViewModel? {
        viewModels.first { $0.asset.localIdentifier == selectedIdentifier }
    }

    private var navigationTitle: String {
        guard viewModels.count > 1,
              let index = viewModels.firstIndex(where: {
                  $0.asset.localIdentifier == selectedIdentifier
              })
        else {
            return selectedViewModel?.asset.mediaType == .video ? "動画" : "写真"
        }
        return "\(index + 1) / \(viewModels.count)"
    }

    private var shareErrorBinding: Binding<Bool> {
        Binding(
            get: { selectedViewModel?.shareFailed == true },
            set: { isPresented in
                if !isPresented {
                    selectedViewModel?.clearShareError()
                }
            }
        )
    }

}

private struct MediaPreviewPage: View {
    @State var viewModel: MediaPreviewViewModel
    let isSelected: Bool

    var body: some View {
        content
            .safeAreaInset(edge: .bottom) {
                metadata
            }
            .task(id: isSelected) {
                guard isSelected, case .idle = viewModel.state else { return }
                await viewModel.load()
            }
            .onDisappear {
                viewModel.stop()
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
                .driveLogGlassButtonStyle()
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
