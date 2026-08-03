import SwiftUI

private struct PendingMapMediaSelection {
    let asset: MediaAssetReference
    let media: [MediaAssetReference]
}

struct FullRouteMapView: View {
    @State private var viewModel: RouteMapViewModel
    @State private var userTrackingRequestID = 0
    @State private var selectedPlace: MapPlaceSelection?
    @State private var pendingMediaSelection: PendingMapMediaSelection?
    let thumbnailLoader: any LoadMediaThumbnailUseCase
    let onSelectMedia: (MediaAssetReference, [MediaAssetReference]) -> Void
    let onBack: () -> Void

    init(
        viewModel: RouteMapViewModel,
        thumbnailLoader: any LoadMediaThumbnailUseCase,
        onSelectMedia: @escaping (MediaAssetReference, [MediaAssetReference]) -> Void = { _, _ in },
        onBack: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.thumbnailLoader = thumbnailLoader
        self.onSelectMedia = onSelectMedia
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            RouteMapView(
                scene: viewModel.scene,
                mode: .full,
                selectedSegmentID: viewModel.selectedSegmentID,
                selectedStayID: viewModel.selectedStayID,
                onSelectSegment: viewModel.selectSegment,
                onSelectStay: viewModel.selectStay,
                staySavingSegmentID: viewModel.staySavingSegmentID,
                onUpdateStay: updateStay,
                media: viewModel.visibleMedia,
                thumbnailLoader: thumbnailLoader,
                onSelectMedia: selectMedia,
                onSelectPlace: { selectedPlace = $0 },
                onTapEmpty: viewModel.clearSelection,
                userTrackingRequestID: userTrackingRequestID
            )
            .ignoresSafeArea()
            GeometryReader { geometry in
                accessibilityControls
                    .padding(.top, 56)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .topLeading
                    )
                    .clipped()
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topLeading) {
            mapBackButton
                .padding(.leading, 12)
                .padding(.top, 8)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("滞在表示を更新できませんでした", isPresented: stayErrorBinding) {
            Button("OK", role: .cancel) {}
        }
        .sheet(item: $selectedPlace, onDismiss: presentPendingMedia) { selection in
            placeSheet(selection)
                .presentationDetents([.medium, .large])
        }
    }
}

private extension FullRouteMapView {
    private var mapBackButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.primary.opacity(0.08), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("日付ページに戻る")
        .accessibilityIdentifier("map.back")
        .zIndex(1)
    }

    private var accessibilityControls: some View {
        VStack(alignment: .leading) {
            LazyVGrid(columns: accessibilityColumns, alignment: .leading, spacing: 0) {
                ForEach(viewModel.scene.movementLabels, id: \.segmentStableID) { movement in
                    accessibilityButton(
                        identifier: "map.polyline",
                        label: "経路、タップして詳細を表示"
                    ) {
                        viewModel.selectSegment(stableID: movement.segmentStableID)
                    }
                }
                ForEach(viewModel.scene.stayAnnotations, id: \.stayStableID) { stay in
                    accessibilityButton(
                        identifier: "map.placeStayControl",
                        label: "滞在 \(stay.text)"
                    ) {
                        selectedPlace = MapPlaceSelection(
                            mediaIdentifiers: [],
                            stayStableIDs: [stay.stayStableID]
                        )
                    }
                }
                ForEach(viewModel.visibleMedia, id: \.localIdentifier) { asset in
                    accessibilityButton(
                        identifier: "map.placeMediaControl",
                        label: asset.mediaType == .video ? "動画" : "写真"
                    ) {
                        selectedPlace = MapPlaceSelection(
                            mediaIdentifiers: [asset.localIdentifier],
                            stayStableIDs: []
                        )
                    }
                }
            }
            selectedCalloutAccessibilityElement
            Spacer()
            HStack {
                Spacer()
                accessibilityButton(
                    identifier: "map.currentLocation",
                    label: "現在地へ移動"
                ) {
                    userTrackingRequestID += 1
                }
            }
        }
    }

    private var accessibilityColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(44), spacing: 0), count: 7)
    }

    private func selectMedia(localIdentifier: String) {
        guard let asset = viewModel.media(localIdentifier: localIdentifier) else { return }
        onSelectMedia(
            asset,
            viewModel.media(atPlaceContaining: [asset.localIdentifier])
        )
    }

    private func selectMediaFromPlace(
        _ asset: MediaAssetReference,
        media: [MediaAssetReference]
    ) {
        pendingMediaSelection = PendingMapMediaSelection(asset: asset, media: media)
        selectedPlace = nil
    }

    private func presentPendingMedia() {
        guard let pendingMediaSelection else { return }
        self.pendingMediaSelection = nil
        onSelectMedia(pendingMediaSelection.asset, pendingMediaSelection.media)
    }

    private func placeSheet(_ selection: MapPlaceSelection) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    let media = viewModel.media(
                        atPlaceContaining: selection.mediaIdentifiers
                    )
                    if !media.isEmpty {
                        placeMediaGrid(media)
                    }
                    let stays = viewModel.stays(stableIDs: selection.stayStableIDs)
                    let displayGroups = StayDisplayGrouping().groups(
                        stays: stays,
                        movements: viewModel.scene.movementLabels
                    )
                    if !displayGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("滞在")
                                .font(.headline)
                            ForEach(displayGroups) { stay in
                                stayRow(stay)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("この場所")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        selectedPlace = nil
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("地図に戻る")
                }
            }
            .accessibilityIdentifier("map.placeSheet")
        }
    }

    private func placeMediaGrid(_ media: [MediaAssetReference]) -> some View {
        MediaGridSection(
            media: media,
            loadThumbnail: { identifier, size in
                try await thumbnailLoader.execute(
                    localIdentifier: identifier,
                    targetSize: size
                )
            },
            onSelect: { asset in
                selectMediaFromPlace(asset, media: media)
            }
        )
    }

    private func stayRow(_ stay: StayDisplayGroup) -> some View {
        HStack {
            Text(stayDuration(seconds: stay.durationSeconds))
                .font(.body.weight(.semibold))
            Spacer()
        }
        .padding(12)
        .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private func stayDuration(seconds: TimeInterval) -> String {
        let minutes = max(0, Int(seconds) / 60)
        guard minutes >= 60 else { return "\(minutes)分" }
        return "\(minutes / 60)時間\(minutes % 60)分"
    }

    private func updateStay(stableID: String, action: StayOverrideAction) {
        Task { @MainActor in
            await viewModel.updateStay(stableID: stableID, action: action)
        }
    }

    private var stayErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.stayUpdateFailed },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissStayError()
                }
            }
        )
    }

    private func accessibilityButton(
        identifier: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Color.clear
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }

    @ViewBuilder
    private var selectedCalloutAccessibilityElement: some View {
        if viewModel.selectedSegmentID != nil {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityLabel("選択中の移動区間")
                .accessibilityIdentifier("map.movementCallout")
        } else if viewModel.selectedStayID != nil {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityLabel("選択中の滞在")
                .accessibilityIdentifier("map.stayCallout")
        }
    }
}
