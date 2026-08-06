import SwiftUI

struct DayDetailView: View {
    @State private var viewModel: DayDetailViewModel
    let onOpenMap: (
        MapScene,
        [MediaAssetReference],
        [MovementDisplayData],
        [StayDisplayData]
    ) -> Void
    let onSelectMedia: (MediaAssetReference, [MediaAssetReference]) -> Void
    private let formatter: DayDetailFormatter

    init(
        viewModel: DayDetailViewModel,
        formatter: DayDetailFormatter = DayDetailFormatter(
            timeZone: SystemTimeZoneProvider().current
        ),
        onOpenMap: @escaping (
            MapScene,
            [MediaAssetReference],
            [MovementDisplayData],
            [StayDisplayData]
        ) -> Void = { _, _, _, _ in },
        onSelectMedia: @escaping (MediaAssetReference, [MediaAssetReference]) -> Void = { _, _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.formatter = formatter
        self.onOpenMap = onOpenMap
        self.onSelectMedia = onSelectMedia
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                if let data = viewModel.data {
                    loadedContent(data: data, availableHeight: proxy.size.height)
                } else {
                    stateContent
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height * 0.75)
                }
            }
        }
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
            await viewModel.observeLibraryChanges()
        }
    }

    private func loadedContent(data: DayDetailData, availableHeight: CGFloat) -> some View {
        VStack(spacing: 16) {
            DayMapPreview(scene: data.mapScene) {
                onOpenMap(data.mapScene, data.media, data.movements, data.stays)
            }
            .frame(height: max(260, availableHeight * 0.55))
            if viewModel.isReprocessing {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("再集計中…")
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("dayDetail.reprocessing")
            }
            if viewModel.isDeleting {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("削除中…")
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("dayDetail.deleting")
            }
            if viewModel.state == .error {
                inlineError
            }
            DaySummaryCard(aggregate: data.aggregate, formatter: formatter)
            MediaGridSection(
                media: data.media,
                loadThumbnail: { localIdentifier, targetSize in
                    try await viewModel.thumbnail(
                        localIdentifier: localIdentifier,
                        targetSize: targetSize
                    )
                },
                onSelect: { asset in
                    onSelectMedia(asset, data.media)
                }
            )
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("読み込み中")
                .controlSize(.large)
                .accessibilityIdentifier("dayDetail.loading")
        case .empty:
            ContentUnavailableView(
                "この日は移動記録がありません",
                systemImage: "figure.walk.motion"
            )
            .accessibilityIdentifier("dayDetail.empty")
        case .error:
            VStack(spacing: 12) {
                ContentUnavailableView(
                    "移動記録を読み込めませんでした",
                    systemImage: "exclamationmark.triangle"
                )
                retryButton
            }
            .accessibilityIdentifier("dayDetail.error")
        case .loaded:
            EmptyView()
        }
    }

    private var inlineError: some View {
        HStack {
            Label("更新できませんでした", systemImage: "exclamationmark.triangle")
                .font(.callout)
            Spacer()
            retryButton
        }
        .accessibilityIdentifier("dayDetail.inlineError")
    }

    private var retryButton: some View {
        Button("再試行") {
            Task { @MainActor in
                await viewModel.load()
            }
        }
        .driveLogGlassButtonStyle()
        .accessibilityIdentifier("dayDetail.retry")
    }
}
