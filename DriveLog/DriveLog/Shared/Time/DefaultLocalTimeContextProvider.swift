import Foundation

struct DefaultLocalTimeContextProvider: LocalTimeContextProviding {
    private let timeZoneProvider: any TimeZoneProviding

    init(timeZoneProvider: any TimeZoneProviding) {
        self.timeZoneProvider = timeZoneProvider
    }

    func makeContext(for date: Date) -> RecordedTimeContext {
        let timeZone = timeZoneProvider.current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        return RecordedTimeContext(
            timeZoneIdentifier: timeZone.identifier,
            utcOffsetSeconds: timeZone.secondsFromGMT(for: date),
            localDateKey: makeLocalDateKey(from: components)
        )
    }

    private func makeLocalDateKey(from components: DateComponents) -> String {
        String(
            format: "%04d-%02d-%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}
