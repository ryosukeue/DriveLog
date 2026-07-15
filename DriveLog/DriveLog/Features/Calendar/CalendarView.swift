import SwiftUI

struct CalendarView: View {
    @State private var viewModel: CalendarViewModel
    @State private var didScrollToCurrentMonth = false
    @State private var scrollMonth: LocalMonth?
    private let today: Date
    private let gridBuilder: CalendarGridBuilder
    private let distanceFormatter: DistanceFormatter
    private let onSelectDate: (String) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    init(
        viewModel: CalendarViewModel,
        today: Date,
        gridBuilder: CalendarGridBuilder = CalendarGridBuilder(),
        distanceFormatter: DistanceFormatter = DistanceFormatter(),
        onSelectDate: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.today = today
        self.gridBuilder = gridBuilder
        self.distanceFormatter = distanceFormatter
        self.onSelectDate = onSelectDate
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 28) {
                ForEach(viewModel.months, id: \.month) { data in
                    if let layout = try? gridBuilder.makeLayout(month: data.month, today: today) {
                        monthSection(data: data, layout: layout)
                            .id(data.month)
                            .task {
                                guard didScrollToCurrentMonth else { return }
                                await viewModel.loadMorePastIfNeeded(visibleMonth: data.month)
                                await viewModel.loadMoreFutureIfNeeded(visibleMonth: data.month)
                            }
                    }
                }
                statusMessage
            }
            .scrollTargetLayout()
            .padding(.vertical)
        }
        .scrollPosition(id: $scrollMonth, anchor: .top)
        .accessibilityIdentifier("calendar.scroll")
        .task {
            guard viewModel.state == .idle else { return }
            await viewModel.load()
        }
        .onChange(of: viewModel.months) { _, months in
            guard !didScrollToCurrentMonth,
                  months.contains(where: { $0.month == viewModel.displayedMonth })
            else { return }
            didScrollToCurrentMonth = true
            scrollMonth = viewModel.displayedMonth
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
    }

    private func monthSection(
        data: CalendarMonthData,
        layout: CalendarGridLayout
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(layout.monthTitle)
                .font(.title2.bold())
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(layout.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol).font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity).accessibilityHidden(true)
                }
                ForEach(Array(layout.daySlots.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day: day, data: data, isToday: day == layout.todayDay)
                    } else {
                        Color.clear.frame(minHeight: 44).accessibilityHidden(true)
                    }
                }
            }
            .padding(.horizontal)
            .accessibilityIdentifier("calendar.month.\(data.month.year)-\(data.month.month)")
        }
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
            VStack(spacing: 2) {
                Text(day, format: .number)
                    .foregroundStyle(isSelected || isToday ? Color.white : Color.primary)
                    .frame(width: 32, height: 32)
                    .background {
                        if isSelected {
                            Circle().fill(Color.accentColor)
                        } else if isToday {
                            Circle().fill(Color.blue)
                        }
                    }
                if let distance {
                    Text(distance).font(.caption2).foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .top)
        }
        .buttonStyle(.plain)
        .disabled(record?.hasValidMovement != true)
        .accessibilityLabel("\(data.month.month)月\(day)日" +
            (distance.map { "、移動距離\($0)" } ?? ""))
        .accessibilityIdentifier("calendar.day.\(data.month.year)-\(data.month.month)-\(day)")
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch viewModel.state {
        case .empty:
            ContentUnavailableView("移動記録がありません", systemImage: "calendar")
                .accessibilityIdentifier("calendar.empty")
        case .error:
            VStack {
                Text("移動記録を読み込めませんでした")
                Button("再試行") { Task { await viewModel.load() } }
                    .accessibilityIdentifier("calendar.retry")
            }
            .accessibilityIdentifier("calendar.error")
        case .idle, .loading, .loaded:
            EmptyView()
        }
    }
}
