protocol Logging: Sendable {
    func debug(_ event: LogEvent)
    func info(_ event: LogEvent)
    func error(_ event: LogEvent)
}
