import SwiftUI

struct ContentView: View {
    let calendarViewModel: CalendarViewModel
    let today: Date

    var body: some View {
        NavigationStack {
            CalendarView(viewModel: calendarViewModel, today: today)
        }
    }
}
