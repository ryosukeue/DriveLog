import SwiftUI

private struct MonthlyMediaPreviewSelection: Identifiable {
    let assets: [MediaAssetReference]
    let selectedIdentifier: String

    var id: String {
        selectedIdentifier
    }
}

struct MonthlyOverviewView: View {
    @State private var viewModel: MonthlyOverviewViewModel
    @State private var isShowingMap = false
    @State private var selectedPreview: MonthlyMediaPreviewSelection?
    let thumbnailLoader: any LoadMediaThumbnailUseCase
    let updateStayOverride: any UpdateStayOverrideUseCase
    let hapticFeedback: any HapticFeedbackProviding
    let makeMediaPreviewViewModel: (MediaAssetReference) -> MediaPreviewViewModel

    init(
        viewModel: MonthlyOverviewViewModel,
        thumbnailLoader: any LoadMediaThumbnailUseCase,
        updateStayOverride: any UpdateStayOverrideUseCase,
        hapticFeedback: any HapticFeedbackProviding,
        makeMediaPreviewViewModel: @escaping (MediaAssetReference) -> MediaPreviewViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.thumbnailLoader = thumbnailLoader
        self.updateStayOverride = updateStayOverride
        self.hapticFeedback = hapticFeedback
        self.makeMediaPreviewViewModel = makeMediaPreviewViewModel
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loaded:
                if let overview = viewModel.overview {
                    loaded(overview)
                } else {
                    emptyView
                }
            case .empty:
                emptyView
            case .error:
                ContentUnavailableView(
                    "月間の地図と写真を読み込めませんでした",
                    systemImage: "map"
                )
                .accessibilityIdentifier("calendar.monthlyOverview.error")
            case .idle, .loading:
                ProgressView("地図と写真を準備中")
                    .accessibilityIdentifier("calendar.monthlyOverview.loading")
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal)
        .fullScreenCover(isPresented: $isShowingMap) {
            if let overview = viewModel.overview {
                FullRouteMapView(
                    viewModel: RouteMapViewModel(
                        scene: overview.mapScene,
                        media: overview.media,
                        movements: overview.movements.map {
                            MovementDisplayData(segment: $0, userClassification: nil)
                        },
                        stays: overview.stays.map {
                            StayDisplayData(segment: $0, overrideAction: nil)
                        },
                        updateStayOverride: updateStayOverride,
                        hapticFeedback: hapticFeedback
                    ),
                    thumbnailLoader: thumbnailLoader,
                    onSelectMedia: selectMedia,
                    onBack: { isShowingMap = false }
                )
            }
        }
        .fullScreenCover(item: $selectedPreview) { selection in
            NavigationStack {
                MediaPreviewView(
                    viewModels: selection.assets.map(makeMediaPreviewViewModel),
                    selectedIdentifier: selection.selectedIdentifier
                )
            }
        }
    }

    private func loaded(_ overview: MonthlyOverviewData) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            monthlyMap(overview)
            MediaGridSection(
                media: overview.media,
                loadThumbnail: { identifier, size in
                    try await thumbnailLoader.execute(
                        localIdentifier: identifier,
                        targetSize: size
                    )
                },
                onSelect: { asset in
                    selectedPreview = MonthlyMediaPreviewSelection(
                        assets: overview.media,
                        selectedIdentifier: asset.localIdentifier
                    )
                },
                title: "月間ギャラリー",
                emptyMessage: "この月の写真・動画はありません",
                gridIdentifier: "calendar.monthlyGallery"
            )
        }
        .padding(.vertical)
    }

    private func monthlyMap(_ overview: MonthlyOverviewData) -> some View {
        Button {
            isShowingMap = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("月間の移動地図")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.subheadline.weight(.semibold))
                        .accessibilityHidden(true)
                }
                ZStack(alignment: .bottomTrailing) {
                    RouteMapView(
                        scene: overview.mapScene,
                        mode: .preview,
                        media: overview.media,
                        thumbnailLoader: thumbnailLoader,
                        onSelectMedia: { identifier in
                            guard let asset = overview.media.first(where: {
                                $0.localIdentifier == identifier
                            }) else { return }
                            selectMedia(asset, overview.media)
                        }
                    )
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    Label("全画面で見る", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(12)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("月間の移動地図を全画面で開く")
        .accessibilityIdentifier("calendar.monthlyMap")
    }

    private var emptyView: some View {
        EmptyView()
    }

    private func selectMedia(_ asset: MediaAssetReference, _ assets: [MediaAssetReference]) {
        selectedPreview = MonthlyMediaPreviewSelection(
            assets: assets,
            selectedIdentifier: asset.localIdentifier
        )
    }
}
