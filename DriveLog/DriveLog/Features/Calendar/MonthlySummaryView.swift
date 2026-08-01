import SwiftUI

struct MonthlySummaryView: View {
    @State private var viewModel: MonthlySummaryViewModel
    private let formatter: DayDetailFormatter
    private let distanceFormatter: DistanceFormatter
    private let onRetry: () -> Void

    init(
        viewModel: MonthlySummaryViewModel,
        formatter: DayDetailFormatter = DayDetailFormatter(
            timeZone: SystemTimeZoneProvider().current
        ),
        distanceFormatter: DistanceFormatter = DistanceFormatter(),
        onRetry: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.formatter = formatter
        self.distanceFormatter = distanceFormatter
        self.onRetry = onRetry
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loaded:
                if let summary = viewModel.summary {
                    loaded(summary)
                } else {
                    emptyView
                }
            case .empty:
                emptyView
            case .error:
                VStack(spacing: 8) {
                    Text("月間サマリーを読み込めませんでした")
                    Button("再試行", action: onRetry)
                }
                .accessibilityIdentifier("calendar.monthlySummary.error")
            case .idle, .loading:
                ProgressView("集計中")
                    .accessibilityIdentifier("calendar.monthlySummary.loading")
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal)
        .accessibilityIdentifier("calendar.monthlySummary")
    }

    private func loaded(_ summary: MonthlySummaryData) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("月間サマリー")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 16)], spacing: 16) {
                summaryItem(
                    title: "総移動距離",
                    value: distanceFormatter.kilometers(
                        fromMeters: summary.totalDistanceMeters
                    ) ?? "--"
                )
                summaryItem(
                    title: "総移動時間",
                    value: formatter.duration(seconds: summary.totalMovementDurationSeconds)
                )
            }
            if summary.cityRankings.isEmpty {
                Text("主要な都市の記録はありません")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("訪れた都市")
                        .font(.headline)
                    ForEach(Array(summary.cityRankings.enumerated()), id: \.element.id) { index, city in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)
                            Text(city.cityName)
                                .font(.body.weight(.semibold))
                            Spacer()
                            Text("\(city.visitCount)回")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(index + 1)位、\(city.cityName)、\(city.visitCount)回")
                    }
                }
            }
        }
        .padding(.vertical)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "この月の移動記録はありません",
            systemImage: "calendar"
        )
        .accessibilityIdentifier("calendar.monthlySummary.empty")
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
