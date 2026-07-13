import SwiftUI

struct DayDetailView: View {
    @State private var viewModel: DayDetailViewModel
    let onOpenMap: (MapScene) -> Void
    private let formatter: DayDetailFormatter

    init(
        viewModel: DayDetailViewModel,
        formatter: DayDetailFormatter = DayDetailFormatter(
            timeZone: SystemTimeZoneProvider().current
        ),
        onOpenMap: @escaping (MapScene) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.formatter = formatter
        self.onOpenMap = onOpenMap
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                if let data = viewModel.data {
                    DayMapPreview(scene: data.mapScene) {
                        onOpenMap(data.mapScene)
                    }
                    .frame(height: max(260, proxy.size.height * 0.55))
                    .padding(.horizontal)
                    DaySummaryCard(aggregate: data.aggregate, formatter: formatter)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard viewModel.state == .idle else { return }
            await viewModel.load()
        }
    }

    private var navigationTitle: String {
        let components = viewModel.localDateKey.split(separator: "-")
        guard components.count == 3,
              let month = Int(components[1]),
              let day = Int(components[2])
        else { return viewModel.localDateKey }
        return "\(month)月\(day)日"
    }
}
