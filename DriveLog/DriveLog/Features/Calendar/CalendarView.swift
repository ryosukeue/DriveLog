import SwiftUI

struct CalendarView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: CalendarViewModel
    @State private var monthlySummaryViewModel: MonthlySummaryViewModel
    @State private var monthlyOverviewViewModel: MonthlyOverviewViewModel
    @State private var selectedMonth: LocalMonth
    @State private var didSetInitialMonth = false
    private let today: Date
    private let gridBuilder: CalendarGridBuilder
    private let distanceFormatter: DistanceFormatter
    private let onSelectDate: (String) -> Void
    private let thumbnailLoader: any LoadMediaThumbnailUseCase
    private let updateStayOverride: any UpdateStayOverrideUseCase
    private let hapticFeedback: any HapticFeedbackProviding
    private let makeMediaPreviewViewModel: (MediaAssetReference) -> MediaPreviewViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    init(
        viewModel: CalendarViewModel,
        monthlySummaryViewModel: MonthlySummaryViewModel,
        monthlyOverviewViewModel: MonthlyOverviewViewModel,
        today: Date,
        gridBuilder: CalendarGridBuilder = CalendarGridBuilder(),
        distanceFormatter: DistanceFormatter = DistanceFormatter(),
        onSelectDate: @escaping (String) -> Void = { _ in },
        thumbnailLoader: any LoadMediaThumbnailUseCase,
        updateStayOverride: any UpdateStayOverrideUseCase,
        hapticFeedback: any HapticFeedbackProviding,
        makeMediaPreviewViewModel: @escaping (MediaAssetReference) -> MediaPreviewViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        _monthlySummaryViewModel = State(initialValue: monthlySummaryViewModel)
        _monthlyOverviewViewModel = State(initialValue: monthlyOverviewViewModel)
        _selectedMonth = State(initialValue: viewModel.displayedMonth)
        self.today = today
        self.gridBuilder = gridBuilder
        self.distanceFormatter = distanceFormatter
        self.onSelectDate = onSelectDate
        self.thumbnailLoader = thumbnailLoader
        self.updateStayOverride = updateStayOverride
        self.hapticFeedback = hapticFeedback
        self.makeMediaPreviewViewModel = makeMediaPreviewViewModel
    }

    var body: some View {
        GeometryReader { proxy in
            let calendarHeight = responsiveCalendarHeight(availableWidth: proxy.size.width)
            ScrollView {
                VStack(spacing: 0) {
                    calendarPager
                        .frame(height: calendarHeight)
                    Divider()
                    CalendarBannerAd()
                    MonthlySummaryView(
                        viewModel: monthlySummaryViewModel,
                        onRetry: reloadSummary
                    )
                    MonthlyOverviewView(
                        viewModel: monthlyOverviewViewModel,
                        thumbnailLoader: thumbnailLoader,
                        updateStayOverride: updateStayOverride,
                        hapticFeedback: hapticFeedback,
                        makeMediaPreviewViewModel: makeMediaPreviewViewModel
                    )
                }
            }
            .scrollIndicators(.hidden)
        }
        .task {
            guard viewModel.state == .idle else { return }
            await viewModel.load()
        }
        .task(id: selectedMonth) {
            await monthlySummaryViewModel.load(month: selectedMonth)
            await monthlyOverviewViewModel.load(month: selectedMonth)
        }
        .task {
            await monthlyOverviewViewModel.observeLibraryChanges()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await monthlyOverviewViewModel.load(month: selectedMonth)
            }
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
        .overlay {
            if viewModel.state == .loading {
                ProgressView("読み込み中")
                    .padding()
                    .driveLogGlassEffect(in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("calendar.loading")
            }
        }
        .overlay(alignment: .bottom) {
            calendarStatusMessage
        }
    }

    private func responsiveCalendarHeight(availableWidth: CGFloat) -> CGFloat {
        let weekCount: Int = if let data = viewModel.months.first(where: {
            $0.month == selectedMonth
        }), let layout = try? gridBuilder.makeLayout(month: data.month, today: today) {
            layout.weekRowCount
        } else {
            6
        }
        let usableWidth = max(0, availableWidth - 32)
        let dayHeight = min(54, max(40, usableWidth / 7 * 0.82))
        let titleAndWeekdayHeight: CGFloat = 68
        let gridSpacing = CGFloat(max(0, weekCount - 1)) * 2
        let verticalPadding: CGFloat = 16
        return titleAndWeekdayHeight + CGFloat(weekCount) * dayHeight +
            gridSpacing + verticalPadding
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
            EmptyView()
        case .error:
            VStack(spacing: 8) {
                Text("移動記録を読み込めませんでした")
                Button("再試行") { Task { await viewModel.load() } }
                    .accessibilityIdentifier("calendar.retry")
            }
            .padding()
            .driveLogGlassEffect(in: RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 12)
            .accessibilityIdentifier("calendar.error")
        case .idle, .loading, .loaded:
            EmptyView()
        }
    }
}
