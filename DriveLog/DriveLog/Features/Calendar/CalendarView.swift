import SwiftUI

struct CalendarView: View {
    @State private var viewModel: CalendarViewModel
    private let today: Date
    private let gridBuilder: CalendarGridBuilder
    private let distanceFormatter: DistanceFormatter
    private let swipeInterpreter: CalendarSwipeInterpreter
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    init(
        viewModel: CalendarViewModel,
        today: Date,
        gridBuilder: CalendarGridBuilder = CalendarGridBuilder(),
        distanceFormatter: DistanceFormatter = DistanceFormatter(),
        swipeInterpreter: CalendarSwipeInterpreter = CalendarSwipeInterpreter()
    ) {
        _viewModel = State(initialValue: viewModel)
        self.today = today
        self.gridBuilder = gridBuilder
        self.distanceFormatter = distanceFormatter
        self.swipeInterpreter = swipeInterpreter
    }

    var body: some View {
        Group {
            if let layout = try? gridBuilder.makeLayout(
                month: viewModel.displayedMonth,
                today: today
            ) {
                calendarContent(layout: layout)
                    .navigationTitle(layout.monthTitle)
            }
        }
        .task {
            guard viewModel.state == .idle else { return }
            await viewModel.load()
        }
    }

    private func calendarContent(layout: CalendarGridLayout) -> some View {
        ZStack {
            VStack(spacing: 16) {
                calendar(layout: layout)
                statusMessage
            }
            if viewModel.state == .loading {
                ProgressView()
                    .controlSize(.large)
                    .accessibilityLabel("読み込み中")
                    .accessibilityIdentifier("calendar.loading")
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch viewModel.state {
        case .empty:
            Text("この月には移動記録がありません")
                .font(.callout)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("calendar.empty")
        case .error:
            VStack(spacing: 8) {
                Text("移動記録を読み込めませんでした")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("calendar.error")
                Button("再試行") {
                    Task { @MainActor in
                        await viewModel.load()
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("calendar.retry")
            }
        case .idle, .loading, .loaded:
            EmptyView()
        }
    }

    private func calendar(layout: CalendarGridLayout) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(layout.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
            ForEach(Array(layout.daySlots.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day: day, isToday: day == layout.todayDay)
                } else {
                    Color.clear.frame(minHeight: 44)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal)
        .accessibilityIdentifier("calendar.grid")
        .accessibilityValue(Text(verbatim: calendarAccessibilityValue))
        .animation(.easeInOut(duration: 0.25), value: viewModel.displayedMonth)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    handleSwipe(translation: value.translation)
                }
        )
        .accessibilityAction(named: Text("前の月")) {
            moveToPreviousMonth()
        }
        .accessibilityAction(named: Text("次の月")) {
            moveToNextMonth()
        }
    }

    private var calendarAccessibilityValue: String {
        "\(viewModel.displayedMonth.year)-\(viewModel.displayedMonth.month)-\(viewModel.state)"
    }

    private func dayCell(day: Int, isToday: Bool) -> some View {
        let data = viewModel.days.first { $0.day == day }
        let isSelected = data?.localDateKey == viewModel.selectedLocalDateKey
        let distance = data.flatMap { data in
            data.hasValidMovement
                ? data.totalDistanceMeters.flatMap(distanceFormatter.kilometers)
                : nil
        }
        return Button {
            if let localDateKey = data?.localDateKey {
                viewModel.select(localDateKey: localDateKey)
            }
        } label: {
            VStack(spacing: 2) {
                Text(day, format: .number)
                    .font(.body)
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
                    Text(distance)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .top)
        }
        .buttonStyle(.plain)
        .disabled(data?.hasValidMovement != true)
        .accessibilityLabel(Text(accessibilityLabel(day: day, distance: distance)))
        .accessibilityIdentifier("calendar.day.\(day)")
    }

    private func accessibilityLabel(day: Int, distance: String?) -> String {
        guard let distance else { return "\(day)日" }
        return "\(day)日、移動距離\(distance)"
    }

    private func handleSwipe(translation: CGSize) {
        guard viewModel.state != .loading,
              let direction = swipeInterpreter.direction(translation: translation)
        else { return }
        switch direction {
        case .previousMonth:
            moveToPreviousMonth()
        case .nextMonth:
            moveToNextMonth()
        }
    }

    private func moveToPreviousMonth() {
        guard viewModel.state != .loading else { return }
        Task { @MainActor in
            await viewModel.showPreviousMonth()
        }
    }

    private func moveToNextMonth() {
        guard viewModel.state != .loading else { return }
        Task { @MainActor in
            await viewModel.showNextMonth()
        }
    }
}
