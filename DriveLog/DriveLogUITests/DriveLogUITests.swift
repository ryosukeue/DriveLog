//
//  DriveLogUITests.swift
//  DriveLogUITests
//
//  Created by ryosuke on 2026/07/13.
//

import XCTest

final class DriveLogUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCalendarEmptyMonthAndSwipe() throws {
        let app = XCUIApplication()
        app.launch()

        let grid = app.otherElements["calendar.grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["この月には移動記録がありません"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["calendar.day.1"].isEnabled)

        let originalMonth = try XCTUnwrap(grid.value as? String)
        grid.swipeLeft()
        expectation(for: NSPredicate(format: "value != %@", originalMonth), evaluatedWith: grid)
        waitForExpectations(timeout: 5)
        expectation(for: NSPredicate(format: "value ENDSWITH '-empty'"), evaluatedWith: grid)
        waitForExpectations(timeout: 5)

        grid.swipeRight()
        expectation(for: NSPredicate(format: "value == %@", originalMonth), evaluatedWith: grid)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testLaunchPerformance() {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
