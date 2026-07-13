@testable import DriveLog
import Testing

struct DriveLogErrorTests {
    @Test func permissionKindCasesSupportEquality() {
        #expect(PermissionKind.location == .location)
        #expect(PermissionKind.motion == .motion)
        #expect(PermissionKind.photoLibrary == .photoLibrary)
        #expect(PermissionKind.location != .motion)
        #expect(PermissionKind.motion != .photoLibrary)
    }

    @Test func allDriveLogErrorCasesSupportEquality() {
        let equalPairs: [(DriveLogError, DriveLogError)] = [
            (.permissionDenied(.location), .permissionDenied(.location)),
            (.permissionRestricted(.motion), .permissionRestricted(.motion)),
            (.monitoringUnavailable, .monitoringUnavailable),
            (.persistenceFailure(code: "TEST_CODE_A"), .persistenceFailure(code: "TEST_CODE_A")),
            (
                .processingFailure(localDateKey: "2026-01-01", code: "TEST_CODE_A"),
                .processingFailure(localDateKey: "2026-01-01", code: "TEST_CODE_A")
            ),
            (.invalidData, .invalidData),
            (.mediaUnavailable, .mediaUnavailable),
            (.mediaAccessLimited, .mediaAccessLimited),
            (.backgroundTaskUnavailable, .backgroundTaskUnavailable),
            (
                .deletionFailure(localDateKey: "2026-01-01"),
                .deletionFailure(localDateKey: "2026-01-01")
            ),
            (.cancelled, .cancelled),
            (.unknown(code: "TEST_CODE_A"), .unknown(code: "TEST_CODE_A"))
        ]

        for pair in equalPairs {
            #expect(pair.0 == pair.1)
        }
    }

    @Test func driveLogErrorCasesWithDifferentAssociatedValuesAreNotEqual() {
        #expect(DriveLogError.permissionDenied(.location) != .permissionDenied(.motion))
        #expect(DriveLogError.permissionRestricted(.motion) != .permissionRestricted(.photoLibrary))
        #expect(
            DriveLogError.persistenceFailure(code: "TEST_CODE_A")
                != .persistenceFailure(code: "TEST_CODE_B")
        )
        #expect(
            DriveLogError.processingFailure(localDateKey: "2026-01-01", code: "TEST_CODE_A")
                != .processingFailure(localDateKey: "2026-01-02", code: "TEST_CODE_A")
        )
        #expect(
            DriveLogError.processingFailure(localDateKey: "2026-01-01", code: "TEST_CODE_A")
                != .processingFailure(localDateKey: "2026-01-01", code: "TEST_CODE_B")
        )
        #expect(
            DriveLogError.deletionFailure(localDateKey: "2026-01-01")
                != .deletionFailure(localDateKey: "2026-01-02")
        )
        #expect(DriveLogError.unknown(code: "TEST_CODE_A") != .unknown(code: "TEST_CODE_B"))
    }

    @Test func differentDriveLogErrorCasesAreNotEqual() {
        #expect(DriveLogError.monitoringUnavailable != .invalidData)
        #expect(DriveLogError.mediaUnavailable != .mediaAccessLimited)
        #expect(DriveLogError.backgroundTaskUnavailable != .cancelled)
    }
}
