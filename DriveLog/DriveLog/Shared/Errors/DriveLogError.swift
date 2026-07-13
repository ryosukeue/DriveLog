enum DriveLogError: Error, Sendable, Equatable {
    case permissionDenied(PermissionKind)
    case permissionRestricted(PermissionKind)
    case monitoringUnavailable
    case persistenceFailure(code: String)
    case processingFailure(localDateKey: String, code: String)
    case invalidData
    case mediaUnavailable
    case mediaAccessLimited
    case backgroundTaskUnavailable
    case deletionFailure(localDateKey: String)
    case cancelled
    case unknown(code: String)
}
