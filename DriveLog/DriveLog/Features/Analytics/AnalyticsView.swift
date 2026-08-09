import Charts
import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel
    @State private var selectedDay: Int?
    @State private var fuelAmount = ""
    @State private var isFullTank = false
    private let distanceFormatter: DistanceFormatter
    private let isPlusEnabled: Bool
    private let onShowPremium: () -> Void

    init(
        viewModel: AnalyticsViewModel,
        distanceFormatter: DistanceFormatter = DistanceFormatter(),
        isPlusEnabled: Bool = true,
        onShowPremium: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.distanceFormatter = distanceFormatter
        self.isPlusEnabled = isPlusEnabled
        self.onShowPremium = onShowPremium
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    monthSelector
                    content
                }
                .padding()
            }
            .navigationTitle("アナリティクス")
            .task {
                if viewModel.state == .idle {
                    await viewModel.load()
                }
                guard runsFuelReviewScreenshot else { return }
                try? await Task.sleep(for: .milliseconds(500))
                proxy.scrollTo("analytics.fuelEconomySection", anchor: .top)
            }
            .onAppear {
                viewModel.refreshVehicleData()
            }
            .onChange(of: viewModel.selectedMonth) { _, _ in
                selectedDay = nil
            }
            .accessibilityIdentifier("analytics.root")
            .alert(
                "燃費記録",
                isPresented: Binding(
                    get: { viewModel.fuelRecordNotice != nil },
                    set: { if !$0 { viewModel.dismissFuelRecordNotice() } }
                )
            ) {
                Button("OK") { viewModel.dismissFuelRecordNotice() }
            } message: {
                Text(viewModel.fuelRecordNotice ?? "")
            }
            .environment(
                \.locale,
                runsFuelReviewScreenshot ? Locale(identifier: "ja_JP") : .autoupdatingCurrent
            )
        }
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
            plusLockedContent {
                fuelEconomySection
            }
            plusLockedContent {
                oilChangeSection
            }
        }
    }

    private func plusLockedContent<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            content()
                .opacity(isPlusEnabled ? 1 : 0.35)
                .allowsHitTesting(isPlusEnabled)
            if !isPlusEnabled {
                Button {
                    onShowPremium()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                        Text("Plusプランでご利用いただけます")
                            .font(.headline)
                    }
                    .foregroundStyle(.primary)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var fuelEconomySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("燃費")
                    .font(.title3.bold())
                Spacer()
                if let vehicle = viewModel.detectedVehicle {
                    Label("\(vehicle.name) 接続中", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            if viewModel.selectedVehicle == nil {
                ContentUnavailableView(
                    "車が登録されていません",
                    systemImage: "fuelpump",
                    description: Text("先に車種登録を行ってください")
                )
            } else {
                fuelEntryForm
                if let overall = viewModel.overallFuelEconomy {
                    summaryItem(
                        title: "総合燃費",
                        value: formattedFuelEconomy(overall)
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("給油ごとの燃費")
                        .font(.headline)
                    if viewModel.fuelEconomyIntervals.isEmpty {
                        Text("満タン給油を2回記録すると燃費が表示されます")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
                    } else {
                        fuelEconomyChart
                    }
                    Text("非満タンの給油量は、次の満タン給油まで合算して計算します。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !displayedFuelRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("給油履歴")
                            .font(.headline)
                        ForEach(displayedFuelRecords.reversed()) { record in
                            HStack {
                                Text(record.date, format: .dateTime.month().day().hour().minute())
                                Spacer()
                                Text(
                                    record.liters,
                                    format: .number.precision(.fractionLength(1...2))
                                )
                                + Text(" L")
                                Text(record.isFullTank ? "満タン" : "非満タン")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(record.isFullTank ? .green : .secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .id("analytics.fuelEconomySection")
        .accessibilityIdentifier("analytics.fuelEconomySection")
    }

    private var fuelEntryForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("給油量を記録")
                .font(.headline)
            HStack(spacing: 8) {
                TextField("0.0", text: $fuelAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Text("L")
                    .foregroundStyle(.secondary)
                Toggle("満タン", isOn: $isFullTank)
                    .fixedSize()
            }
            Button {
                guard let liters = fuelAmountValue else { return }
                if viewModel.recordFuel(liters: liters, isFullTank: isFullTank) {
                    fuelAmount = ""
                    isFullTank = false
                }
            } label: {
                Label("給油を記録", systemImage: "fuelpump.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.detectedVehicle == nil || fuelAmountValue == nil)

            if viewModel.detectedVehicle == nil {
                Text("登録した車のBluetoothまたはCarPlay接続中のみ記録できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var fuelEconomyChart: some View {
        Chart(viewModel.fuelEconomyIntervals) { interval in
            BarMark(
                x: .value("給油日", interval.endDate, unit: .day),
                y: .value("燃費（km/L）", interval.kilometersPerLiter)
            )
            .foregroundStyle(Color(hex: viewModel.selectedVehicle?.colorHex ?? "#007AFF"))
            .cornerRadius(4)
            .annotation(position: .top) {
                Text(interval.kilometersPerLiter, format: .number.precision(.fractionLength(1)))
                    .font(.caption2.monospacedDigit())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let value = value.as(Double.self) {
                        Text("\(value.formatted(.number.precision(.fractionLength(0...1))))")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
            }
        }
        .frame(height: 220)
        .accessibilityLabel("給油ごとの燃費の棒グラフ")
    }

    private var oilChangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("オイル交換")
                .font(.title3.bold())
            if viewModel.vehicles.isEmpty {
                Text("車を登録するとオイル交換までの距離が表示されます")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.vehicles) { vehicle in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label {
                                Text(vehicle.name)
                            } icon: {
                                Circle()
                                    .fill(Color(hex: vehicle.colorHex))
                                    .frame(width: 9, height: 9)
                            }
                            Spacer()
                            Text(oilRemainingText(vehicle))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(oilStatusColor(vehicle))
                        }
                        ProgressView(value: oilProgress(vehicle))
                            .tint(oilStatusColor(vehicle))
                    }
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("analytics.oilChangeSection")
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

    private var fuelAmountValue: Double? {
        let normalized = fuelAmount
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value.isFinite, value > 0 else { return nil }
        return value
    }

    private var runsFuelReviewScreenshot: Bool {
        #if DEBUG
            ProcessInfo.processInfo.arguments.contains("-ui-testing-fuel-review")
        #else
            false
        #endif
    }

    private var displayedFuelRecords: [VehicleFuelRecord] {
        viewModel.fuelRecords.filter { record in
            let components = Calendar.current.dateComponents([.year, .month], from: record.date)
            return components.year == viewModel.selectedMonth.year
                && components.month == viewModel.selectedMonth.month
        }
    }

    private func formattedFuelEconomy(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(1)))) km/L"
    }

    private func oilProgress(_ vehicle: VehicleProfile) -> Double {
        let traveled = vehicle.odometerKilometers
            - vehicle.lastOilChangeOdometerKilometers
        return min(max(traveled / vehicle.oilChangeIntervalKilometers, 0), 1)
    }

    private func oilRemainingText(_ vehicle: VehicleProfile) -> String {
        let remaining = vehicle.oilChangeRemainingKilometers
        if remaining < 0 {
            return "\(abs(remaining).formatted(.number.precision(.fractionLength(0)))) km超過"
        }
        return "あと \(remaining.formatted(.number.precision(.fractionLength(0)))) km"
    }

    private func oilStatusColor(_ vehicle: VehicleProfile) -> Color {
        if vehicle.oilChangeRemainingKilometers < 0 {
            return .red
        }
        if vehicle.oilChangeRemainingKilometers <= 500 {
            return .orange
        }
        return Color(hex: vehicle.colorHex)
    }
}
