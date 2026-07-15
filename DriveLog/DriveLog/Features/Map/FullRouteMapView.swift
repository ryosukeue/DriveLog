import SwiftUI

struct FullRouteMapView: View {
    @State private var viewModel: RouteMapViewModel
    @State private var userTrackingRequestID = 0
    let thumbnailLoader: any LoadMediaThumbnailUseCase
    let onSelectMedia: (MediaAssetReference) -> Void

    init(
        viewModel: RouteMapViewModel,
        thumbnailLoader: any LoadMediaThumbnailUseCase,
        onSelectMedia: @escaping (MediaAssetReference) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.thumbnailLoader = thumbnailLoader
        self.onSelectMedia = onSelectMedia
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
                onTapEmpty: viewModel.clearSelection,
                userTrackingRequestID: userTrackingRequestID
            )
            accessibilityControls
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("経路")
        .navigationBarTitleDisplayMode(.inline)
        .alert("滞在表示を更新できませんでした", isPresented: stayErrorBinding) {
            Button("OK", role: .cancel) {}
        }
    }

    private var accessibilityControls: some View {
        VStack {
            HStack(spacing: 0) {
                ForEach(viewModel.scene.movementLabels, id: \.segmentStableID) { movement in
                    accessibilityButton(
                        identifier: "map.movementLabel",
                        label: "移動区間 \(movement.text)"
                    ) {
                        viewModel.selectSegment(stableID: movement.segmentStableID)
                    }
                }
                ForEach(viewModel.scene.stayAnnotations, id: \.stayStableID) { stay in
                    accessibilityButton(
                        identifier: "map.stayAnnotation",
                        label: "滞在 \(stay.text)"
                    ) {
                        viewModel.selectStay(stableID: stay.stayStableID)
                    }
                }
                ForEach(viewModel.visibleMedia, id: \.localIdentifier) { asset in
                    accessibilityButton(
                        identifier: "map.mediaAnnotation",
                        label: asset.mediaType == .video ? "動画" : "写真"
                    ) {
                        onSelectMedia(asset)
                    }
                }
                Spacer()
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

    private func selectMedia(localIdentifier: String) {
        guard let asset = viewModel.media(localIdentifier: localIdentifier) else { return }
        onSelectMedia(asset)
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
