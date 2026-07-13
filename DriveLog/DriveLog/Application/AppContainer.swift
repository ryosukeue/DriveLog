final class AppContainer {
    let logger: any Logging
    let clock: any Clock
    let timeZoneProvider: any TimeZoneProviding
    let localTimeContextProvider: any LocalTimeContextProviding

    convenience init() {
        let timeZoneProvider = SystemTimeZoneProvider()
        self.init(
            logger: OSLogLogger(),
            clock: SystemClock(),
            timeZoneProvider: timeZoneProvider,
            localTimeContextProvider: DefaultLocalTimeContextProvider(
                timeZoneProvider: timeZoneProvider
            )
        )
    }

    init(
        logger: any Logging,
        clock: any Clock,
        timeZoneProvider: any TimeZoneProviding,
        localTimeContextProvider: any LocalTimeContextProviding
    ) {
        self.logger = logger
        self.clock = clock
        self.timeZoneProvider = timeZoneProvider
        self.localTimeContextProvider = localTimeContextProvider
    }
}
