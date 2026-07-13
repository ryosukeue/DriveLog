import SwiftData
import SwiftUI

@main
struct DriveLogApp: App {
    private let calendarViewModel: CalendarViewModel?
    private let today: Date
    private let modelContainer: ModelContainer?

    @MainActor
    init() {
        let container = AppContainer()
        let now = container.clock.now
        today = now
        do {
            let modelContainer = try DriveLogModelContainerFactory.make()
            self.modelContainer = modelContainer
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = container.timeZoneProvider.current
            let components = calendar.dateComponents([.year, .month], from: now)
            let month = LocalMonth(year: components.year ?? 1970, month: components.month ?? 1)
            calendarViewModel = container.makeCalendarViewModel(
                modelContainer: modelContainer,
                displayedMonth: month
            )
        } catch {
            modelContainer = nil
            calendarViewModel = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let calendarViewModel {
                ContentView(calendarViewModel: calendarViewModel, today: today)
            } else {
                ContentUnavailableView(
                    "起動できませんでした",
                    systemImage: "exclamationmark.triangle",
                    description: Text("アプリを終了して、もう一度お試しください")
                )
                .accessibilityIdentifier("app.startup.error")
            }
        }
    }
}
