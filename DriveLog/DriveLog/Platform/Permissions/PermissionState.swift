struct PermissionState: Sendable, Equatable {
    let location: LocationPermissionState
    let motion: MotionPermissionState
    let photos: PhotoPermissionState
}

enum LocationPermissionState: Sendable, Equatable {
    case notDetermined
    case restricted
    case denied
    case whenInUse
    case always
}

enum MotionPermissionState: Sendable, Equatable {
    case notDetermined
    case restricted
    case denied
    case authorized
}

enum PhotoPermissionState: Sendable, Equatable {
    case notDetermined
    case restricted
    case denied
    case limited
    case authorized
}
