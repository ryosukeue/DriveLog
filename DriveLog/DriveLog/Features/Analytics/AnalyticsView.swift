import Charts
import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel
    @State private var selectedDay: Int?
    private let distanceFormatter: DistanceFormatter

    init(
        viewModel: AnalyticsViewModel,
        distanceFormatter: DistanceFormatter = DistanceFormatter()
    ) {
        _viewModel = State(initialValue: viewModel)
        self.distanceFormatter = distanceFormatter
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                monthSelector
                content
            }
            .padding()
        }
        .navigationTitle("アナリティクス")
        .task {
            guard viewModel.state == .idle else { return }
            await viewModel.load()
        }
        .onChange(of: viewModel.selectedMonth) { _, _ in
            selectedDay = nil
        }
        .accessibilityIdentifier("analytics.root")
    }

    private var monthSelector: some View {
        HStack {
            Button {
                Task { await viewModel.moveToPreviousMonth() }
            } label: {
                Label("前の月", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .frame(width: 36, height: 36)
            }
            .driveLogGlassButtonStyle()
            .accessibilityIdentifier("analytics.previousMonth")

            Spacer()
            Text(monthTitle)
                .font(.title2.bold())
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)
            Spacer()

            Button {
                Task { await viewModel.moveToNextMonth() }
            } label: {
                Label("次の月", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
                    .frame(width: 36, height: 36)
            }
            .driveLogGlassButtonStyle()
            .disabled(!viewModel.canMoveToNextMonth)
            .accessibilityIdentifier("analytics.nextMonth")
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width > 60 {
                        Task { await viewModel.moveToPreviousMonth() }
                    } else if value.translation.width < -60 {
                        Task { await viewModel.moveToNextMonth() }
                    }
                }
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loaded:
            if let series = viewModel.series {
                loaded(series)
            }
        case .error:
            ContentUnavailableView {
                Label("移動距離を読み込めませんでした", systemImage: "chart.bar.xaxis")
            } actions: {
                Button("再試行") {
                    Task { await viewModel.load() }
                }
                .driveLogGlassButtonStyle()
            }
            .accessibilityIdentifier("analytics.error")
        case .idle, .loading:
            ProgressView("集計中")
                .frame(maxWidth: .infinity, minHeight: 240)
                .accessibilityIdentifier("analytics.loading")
        }
    }

    private func loaded(_ series: MonthlyDistanceSeriesData) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 12) {
                summaryItem(
                    title: "月の移動距離",
                    value: formattedDistance(series.totalDistanceMeters)
                )
                summaryItem(
                    title: "移動した日",
                    value: "\(series.activeDayCount)日"
                )
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("日ごとの移動距離")
                        .font(.headline)
                    Spacer()
                    if let selected = selectedDistance(in: series) {
                        Text("\(selected.day)日  \(formattedDistance(selected.distanceMeters))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("analytics.selectedDistance")
                    }
                }
                distanceChart(series)
                chartLegend(series)
            }
        }
    }

    private func distanceChart(_ series: MonthlyDistanceSeriesData) -> some View {
        Chart(series.days) { day in
            BarMark(
                x: .value("日", day.day),
                y: .value("その他の移動距離（km）", day.otherVehicleDistanceMeters / 1000)
            )
            .foregroundStyle(Color.red)
            .cornerRadius(3)
            .opacity(day.day == selectedDay || selectedDay == nil ? 1 : 0.5)
            if day.selectedVehicleDistanceMeters > 0 {
                BarMark(
                    x: .value("日", day.day),
                    yStart: .value(
                        "車両の開始距離（km）",
                        day.otherVehicleDistanceMeters / 1000
                    ),
                    yEnd: .value("総移動距離（km）", day.distanceMeters / 1000)
                )
                .foregroundStyle(Color(hex: day.selectedVehicleColorHex ?? "#007AFF"))
                .cornerRadius(3)
                .opacity(day.day == selectedDay || selectedDay == nil ? 1 : 0.5)
            }
            if day.day == selectedDay {
                RuleMark(x: .value("選択した日", day.day))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
            }
        }
        .chartXScale(domain: 0.5 ... Double(series.days.count) + 0.5)
        .chartXAxis {
            AxisMarks(values: [1, 5, 10, 15, 20, 25, series.days.count]) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        Text("\(day)日")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let distance = value.as(Double.self) {
                        Text(distance, format: .number.precision(.fractionLength(0 ... 1)))
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDay)
        .frame(height: 300)
        .accessibilityIdentifier("analytics.distanceChart")
        .accessibilityLabel("日ごとの移動距離の棒グラフ")
    }

    @ViewBuilder
    private func chartLegend(_ series: MonthlyDistanceSeriesData) -> some View {
        HStack(spacing: 16) {
            Label {
                Text("その他")
            } icon: {
                Circle().fill(.red).frame(width: 8, height: 8)
            }
            if let vehicle = series.selectedVehicle {
                Label {
                    Text(vehicle.name)
                } icon: {
                    Circle()
                        .fill(Color(hex: vehicle.colorHex))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("analytics.vehicleLegend")
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var monthTitle: String {
        "\(viewModel.selectedMonth.year)年\(viewModel.selectedMonth.month)月"
    }

    private func selectedDistance(in series: MonthlyDistanceSeriesData) -> DailyDistanceData? {
        guard let selectedDay else { return nil }
        return series.days.first { $0.day == selectedDay }
    }

    private func formattedDistance(_ meters: Double) -> String {
        distanceFormatter.kilometers(fromMeters: meters) ?? "0 km"
    }
}
