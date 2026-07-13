@testable import DriveLog
import SwiftUI
import Testing

@Suite("Media grid column policy")
struct MediaGridSectionTests {
    @Test("uses four columns for standard Dynamic Type")
    func standard() {
        let policy = MediaGridColumnPolicy()

        #expect(policy.columnCount(for: .medium) == 4)
        #expect(policy.columnCount(for: .xxxLarge) == 4)
    }

    @Test("uses three columns for accessibility Dynamic Type")
    func accessibility() {
        let policy = MediaGridColumnPolicy()

        #expect(policy.columnCount(for: .accessibility1) == 3)
        #expect(policy.columnCount(for: .accessibility5) == 3)
    }
}
