import SwiftUI

struct FullRouteMapView: View {
    @State private var viewModel: RouteMapViewModel

    init(viewModel: RouteMapViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        RouteMapView(
            scene: viewModel.scene,
            mode: .full,
            selectedSegmentID: viewModel.selectedSegmentID,
            selectedStayID: viewModel.selectedStayID,
            onSelectSegment: viewModel.selectSegment,
            onSelectStay: viewModel.selectStay,
            onTapEmpty: viewModel.clearSelection
        )
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("経路")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("routeMap.full")
    }
}
