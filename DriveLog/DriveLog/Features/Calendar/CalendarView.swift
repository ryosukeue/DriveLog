import SwiftUI

struct CalendarView: View {
    @State private var viewModel: CalendarViewModel
    @State private var monthlySummaryViewModel: MonthlySummaryViewModel
    @State private var selectedMonth: LocalMonth
    @State private var didSetInitialMonth = false
    private let today: Date
    private let gridBuilder: CalendarGridBuilder
    private let distanceFormatter: DistanceFormatter
    private let onSelectDate: (String) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    init(
        viewModel: CalendarViewModel,
        monthlySummaryViewModel: MonthlySummaryViewModel,
        today: Date,
        gridBuilder: CalendarGridBuilder = CalendarGridBuilder(),
        distanceFormatter: DistanceFormatter = DistanceFormatter(),
        onSelectDate: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        _monthlySummaryViewModel = State(initialValue: monthlySummaryViewModel)
        _selectedMonth = State(initialValue: viewModel.displayedMonth)
        self.today = today
        self.gridBuilder = gridBuilder
        self.distanceFormatter = distanceFormatter
        self.onSelectDate = onSelectDate
    }

    var body: some View {
        GeometryReader { proxy in
            let calendarHeight = max(260, proxy.size.height * 0.4)
            VStack(spacing: 0) {
                calendarPager
                    .frame(height: calendarHeight)
                Divider()
                MonthlySummaryView(
                    viewModel: monthlySummaryViewModel,
                    onRetry: reloadSummary
                )
                .frame(height: max(0, proxy.size.height - calendarHeight))
            }
        }
        .task {
            guard viewModel.state == .idle else { return }
            await viewModel.load()
        }
        .task(id: selectedMonth) {
            await monthlySummaryViewModel.load(month: selectedMonth)
        }
        .onChange(of: selectedMonth) { _, month in
            viewModel.select(month: month)
            Task {
                await viewModel.loadMorePastIfNeeded(visibleMonth: month)
                await viewModel.loadMoreFutureIfNeeded(visibleMonth: month)
            }
        }
        .onChange(of: viewModel.months) { _, months in
            guard !didSetInitialMonth,
                  months.contains(where: { $0.month == viewModel.displayedMonth })
            else { return }
            didSetInitialMonth = true
            selectedMonth = viewModel.displayedMonth
        }
        .navigationTitle("移動ログ")
        .overlay {
            if viewModel.state == .loading {
                ProgressView("読み込み中")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("calendar.loading")
            }
        }
        .overlay(alignment: .bottom) {
            calendarStatusMessage
        }
    }

    private var calendarPager: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedMonth) {
                ForEach(viewModel.months, id: \.month) { data in
                    if let layout = try? gridBuilder.makeLayout(month: data.month, today: today) {
                        monthSection(data: data, layout: layout)
                            .tag(data.month)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("calendar.pager")
        .accessibilityLabel("月のカレンダー")
        .accessibilityAction(named: "前の月") {
            selectedMonth = selectedMonth.adding(months: -1)
        }
        .accessibilityAction(named: "次の月") {
            selectedMonth = selectedMonth.adding(months: 1)
        }
    }

    private func monthSection(
        data: CalendarMonthData,
        layout: CalendarGridLayout
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(layout.monthTitle)
                .font(.title3.bold())
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(layout.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 20)
                        .accessibilityHidden(true)
                }
                ForEach(Array(layout.daySlots.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day: day, data: data, isToday: day == layout.todayDay)
                    } else {
                        Color.clear.frame(minHeight: 40).accessibilityHidden(true)
                    }
                }
            }
            .padding(.horizontal)
            .accessibilityIdentifier("calendar.month.\(data.month.year)-\(data.month.month)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 8)
    }

    private func dayCell(day: Int, data: CalendarMonthData, isToday: Bool) -> some View {
        let record = data.days.first { $0.day == day }
        let isSelected = record?.localDateKey == viewModel.selectedLocalDateKey
        let distance = record.flatMap {
            $0.hasValidMovement ? $0.totalDistanceMeters.flatMap(distanceFormatter.kilometers) : nil
        }
        return Button {
            guard let key = record?.localDateKey else { return }
            viewModel.select(localDateKey: key)
            guard viewModel.navigationLocalDateKey == key else { return }
            onSelectDate(key)
            viewModel.consumeNavigation()
        } label: {
            VStack(spacing: 1) {
                Text(day, format: .number)
                    .foregroundStyle(isSelected || isToday ? Color.white : Color.primary)
                    .frame(width: 30, height: 30)
                    .background {
                        if isSelected {
                            Circle().fill(Color.accentColor)
                        } else if isToday {
                            Circle().fill(Color.blue)
                        }
                    }
                if let distance {
                    Text(distance)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(record?.hasValidMovement != true)
        .accessibilityLabel("\(data.month.month)月\(day)日" +
            (distance.map { "、移動距離\($0)" } ?? ""))
        .accessibilityIdentifier("calendar.day.\(data.month.year)-\(data.month.month)-\(day)")
    }

    private func reloadSummary() {
        Task {
            await monthlySummaryViewModel.load(month: selectedMonth)
        }
    }

    @ViewBuilder
    private var calendarStatusMessage: some View {
        switch viewModel.state {
        case .empty:
            ContentUnavailableView("移動記録がありません", systemImage: "calendar")
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
                .accessibilityIdentifier("calendar.empty")
        case .error:
            VStack(spacing: 8) {
                Text("移動記録を読み込めませんでした")
                Button("再試行") { Task { await viewModel.load() } }
                    .accessibilityIdentifier("calendar.retry")
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 12)
            .accessibilityIdentifier("calendar.error")
        case .idle, .loading, .loaded:
            EmptyView()
        }
    }
}
