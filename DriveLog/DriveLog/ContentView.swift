import SwiftUI

struct ContentView: View {
    let calendarViewModel: CalendarViewModel
    let today: Date
    let makeDayDetailViewModel: (String) -> DayDetailViewModel
    @State private var selectedLocalDateKey: String?

    var body: some View {
        NavigationStack {
            CalendarView(
                viewModel: calendarViewModel,
                today: today,
                onSelectDate: { selectedLocalDateKey = $0 }
            )
            .navigationDestination(item: $selectedLocalDateKey) { localDateKey in
                DayDetailView(
                    viewModel: makeDayDetailViewModel(localDateKey)
                )
            }
        }
    }
}
