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
    func testCalendarNavigatesToDayDetail() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-day-detail")
        app.launch()

        let enabledDay = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'calendar.day.' AND enabled == true")
        ).firstMatch
        XCTAssertTrue(enabledDay.waitForExistence(timeout: 5))
        enabledDay.tap()

        XCTAssertTrue(app.buttons["dayDetail.mapPreview"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["dayDetail.summary"].exists)
        XCTAssertTrue(app.otherElements["dayDetail.statistics"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.otherElements["calendar.grid"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testFullMapCalloutFlow() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-day-detail")
        app.launch()

        let enabledDay = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'calendar.day.' AND enabled == true")
        ).firstMatch
        XCTAssertTrue(enabledDay.waitForExistence(timeout: 5))
        enabledDay.tap()
        let preview = app.buttons["dayDetail.mapPreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        preview.tap()

        XCTAssertTrue(app.buttons["BackButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["map.currentLocation"].exists)
        let movement = app.descendants(matching: .any)["map.movementLabel"].firstMatch
        XCTAssertTrue(movement.waitForExistence(timeout: 5))
        movement.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["map.movementCallout"].firstMatch
                .waitForExistence(timeout: 5)
        )

        let stay = app.descendants(matching: .any)["map.stayAnnotation"].firstMatch
        XCTAssertTrue(stay.waitForExistence(timeout: 5))
        stay.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["map.stayCallout"].firstMatch
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.descendants(matching: .any)["map.movementCallout"].firstMatch.exists)

        app.buttons["BackButton"].tap()
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
