import CoreMotion
import Foundation

struct MotionActivitySnapshot: Sendable {
    let startDate: Date
    let isAutomotive: Bool
    let isWalking: Bool
    let isRunning: Bool
    let isCycling: Bool
    let isStationary: Bool
    let isUnknown: Bool
    let confidence: CMMotionActivityConfidence
}

@MainActor
final class CoreMotionProvider: MotionProviding {
    nonisolated let events: AsyncStream<MotionProviderEvent>
    nonisolated let activityChanges: AsyncStream<MotionEventData>

    private let manager: CMMotionActivityManager
    private let localTimeContextProvider: any LocalTimeContextProviding
    private let continuation: AsyncStream<MotionProviderEvent>.Continuation
    private let activityContinuation: AsyncStream<MotionEventData>.Continuation
    private var state: MotionMonitoringState = .stopped

    init(
        manager: CMMotionActivityManager = CMMotionActivityManager(),
        localTimeContextProvider: any LocalTimeContextProviding
    ) {
        let stream = AsyncStream.makeStream(of: MotionProviderEvent.self)
        let activityStream = AsyncStream.makeStream(of: MotionEventData.self)
        events = stream.stream
        activityChanges = activityStream.stream
        continuation = stream.continuation
        activityContinuation = activityStream.continuation
        self.manager = manager
        self.localTimeContextProvider = localTimeContextProvider
    }

    var monitoringState: MotionMonitoringState {
        get async { state }
    }

    func startMonitoring() async throws {
        guard CMMotionActivityManager.isActivityAvailable() else {
            setState(.unavailable)
            throw DriveLogError.monitoringUnavailable
        }
        guard CMMotionActivityManager.authorizationStatus() != .denied else {
            let error = DriveLogError.permissionDenied(.motion)
            setState(.failed(code: "permission_denied"))
            continuation.yield(.error(error))
            throw error
        }
        setState(.starting)
        manager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else { return }
            let snapshot = MotionActivitySnapshot(
                startDate: activity.startDate,
                isAutomotive: activity.automotive, isWalking: activity.walking,
                isRunning: activity.running, isCycling: activity.cycling,
                isStationary: activity.stationary, isUnknown: activity.unknown,
                confidence: activity.confidence
            )
            Task { @MainActor [weak self] in
                self?.send(snapshot)
            }
        }
        setState(.running)
    }

    func stopMonitoring() async {
        manager.stopActivityUpdates()
        setState(.stopped)
    }

    func convert(_ snapshot: MotionActivitySnapshot) -> MotionEventData {
        let context = localTimeContextProvider.makeContext(for: snapshot.startDate)
        return MotionEventData(
            startDate: snapshot.startDate, endDate: nil,
            isAutomotive: snapshot.isAutomotive, isWalking: snapshot.isWalking,
            isRunning: snapshot.isRunning, isCycling: snapshot.isCycling,
            isStationary: snapshot.isStationary, isUnknown: snapshot.isUnknown,
            confidence: Self.confidence(from: snapshot.confidence),
            timeZoneIdentifier: context.timeZoneIdentifier,
            utcOffsetSeconds: context.utcOffsetSeconds, localDateKey: context.localDateKey
        )
    }

    func sendCallbackError() {
        let error = DriveLogError.unknown(code: "core_motion")
        setState(.failed(code: "motion_error"))
        continuation.yield(.error(error))
    }

    func send(_ snapshot: MotionActivitySnapshot) {
        let event = convert(snapshot)
        continuation.yield(.motion(event))
        activityContinuation.yield(event)
    }

    private func setState(_ newState: MotionMonitoringState) {
        state = newState
        continuation.yield(.stateChanged(newState))
    }

    private static func confidence(
        from confidence: CMMotionActivityConfidence
    ) -> MotionConfidence {
        switch confidence {
        case .medium: .medium
        case .high: .high
        default: .low
        }
    }
}
