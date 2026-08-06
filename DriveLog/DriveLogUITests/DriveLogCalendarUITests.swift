import XCTest

final class DriveLogCalendarUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCalendarUsesMonthlyPageSwipeAndSummary() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-calendar")
        app.launch()

        let pager = app.descendants(matching: .any)["calendar.pager"]
        XCTAssertTrue(pager.waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.otherElements.matching(
                NSPredicate(format: "identifier BEGINSWITH 'calendar.month.'")
            ).firstMatch.waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["calendar.monthlySummary"]
                .waitForExistence(timeout: 5)
        )
        pager.swipeLeft()
        XCTAssertTrue(pager.exists)
        XCTAssertFalse(app.navigationBars.staticTexts["移動ログ"].exists)
    }
}
