import SwiftUI

struct CalendarView: View {
    @State private var viewModel: CalendarViewModel
    private let today: Date
    private let gridBuilder: CalendarGridBuilder
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    init(
        viewModel: CalendarViewModel,
        today: Date,
        gridBuilder: CalendarGridBuilder = CalendarGridBuilder()
    ) {
        _viewModel = State(initialValue: viewModel)
        self.today = today
        self.gridBuilder = gridBuilder
    }

    var body: some View {
        Group {
            if let layout = try? gridBuilder.makeLayout(
                month: viewModel.displayedMonth,
                today: today
            ) {
                calendar(layout: layout)
                    .navigationTitle(layout.monthTitle)
            }
        }
        .task {
            guard viewModel.state == .idle else { return }
            await viewModel.load()
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
    }

    private func dayCell(day: Int, isToday: Bool) -> some View {
        let data = viewModel.days.first { $0.day == day }
        let isSelected = data?.localDateKey == viewModel.selectedLocalDateKey
        return Button {
            if let localDateKey = data?.localDateKey {
                viewModel.select(localDateKey: localDateKey)
            }
        } label: {
            Text(day, format: .number)
                .font(.body)
                .foregroundStyle(isSelected || isToday ? Color.white : Color.primary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if isSelected {
                        Circle().fill(Color.accentColor)
                    } else if isToday {
                        Circle().fill(Color.blue)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(data?.hasValidMovement != true)
        .accessibilityLabel(Text("\(day)日"))
        .accessibilityIdentifier("calendar.day.\(day)")
    }
}
