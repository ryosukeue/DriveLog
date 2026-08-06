import XCTest

final class DriveLogAnalyticsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAnalyticsTabShowsDailyDistanceChart() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-day-detail")
        app.launch()

        let analyticsTab = app.tabBars.buttons["アナリティクス"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5))
        analyticsTab.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["analytics.root"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["analytics.distanceChart"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.buttons["analytics.previousMonth"].exists)
        XCTAssertFalse(app.buttons["analytics.nextMonth"].isEnabled)
    }
}
