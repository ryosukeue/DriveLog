import SwiftData
import SwiftUI

@main
struct DriveLogApp: App {
    private let calendarViewModel: CalendarViewModel?
    private let appContainer: AppContainer
    private let today: Date
    private let modelContainer: ModelContainer?

    @MainActor
    init() {
        let container = AppContainer()
        appContainer = container
        let now = container.clock.now
        today = now
        do {
            #if DEBUG
                let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing-day-detail")
            #else
                let isUITesting = false
            #endif
            let modelContainer = try DriveLogModelContainerFactory.make(
                isStoredInMemoryOnly: isUITesting
            )
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = container.timeZoneProvider.current
            let components = calendar.dateComponents([.year, .month], from: now)
            let month = LocalMonth(year: components.year ?? 1970, month: components.month ?? 1)
            #if DEBUG
                if isUITesting {
                    try Self.seedUITestData(
                        modelContainer: modelContainer,
                        now: now,
                        calendar: calendar
                    )
                }
            #endif
            self.modelContainer = modelContainer
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
            if let calendarViewModel, let modelContainer {
                ContentView(
                    calendarViewModel: calendarViewModel,
                    today: today,
                    makeDayDetailViewModel: { localDateKey in
                        appContainer.makeDayDetailViewModel(
                            modelContainer: modelContainer,
                            localDateKey: localDateKey
                        )
                    }
                )
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

    #if DEBUG
        @MainActor
        private static func seedUITestData(
            modelContainer: ModelContainer,
            now: Date,
            calendar: Calendar
        ) throws {
            let components = calendar.dateComponents([.year, .month, .day], from: now)
            guard let year = components.year,
                  let month = components.month,
                  let day = components.day
            else { throw DriveLogError.invalidData }
            let localDateKey = String(format: "%04d-%02d-%02d", year, month, day)
            let startDate = now.addingTimeInterval(-3600)
            let context = ModelContext(modelContainer)
            context.insert(
                DayAggregateModel(
                    localDateKey: localDateKey,
                    totalDistanceMeters: 5200,
                    totalMovementDurationSeconds: 3600,
                    startDate: startDate,
                    endDate: now,
                    locationRecordCount: 120,
                    rejectedLocationCount: 3,
                    mediaCountCache: 0,
                    automaticClassificationRawValue: "automotiveLike",
                    hasValidMovement: true,
                    movementSegmentCount: 2,
                    staySegmentCount: 1,
                    totalStayDurationSeconds: 600,
                    automotiveDurationSeconds: 3000,
                    walkingDurationSeconds: 600,
                    sourceRawRevision: 1,
                    generatedAt: now
                )
            )
            context.insert(
                DayProcessingStateModel(
                    localDateKey: localDateKey,
                    rawRevision: 1,
                    processedRevision: 1,
                    statusRawValue: "completed",
                    lastAttemptDate: now,
                    lastSuccessfulDate: now,
                    lastErrorCode: nil,
                    updatedAt: now
                )
            )
            try context.save()
        }
    #endif
}
