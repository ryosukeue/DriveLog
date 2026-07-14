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
    func testDayDetailShowsDeleteConfirmation() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-day-detail")
        app.launch()

        let enabledDay = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'calendar.day.' AND enabled == true")
        ).firstMatch
        XCTAssertTrue(enabledDay.waitForExistence(timeout: 5))
        enabledDay.tap()

        let menu = app.buttons["dayDetail.menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        XCTAssertEqual(menu.label, "その他の操作")
        menu.tap()
        let deleteMenuItem = app.buttons["この日の記録を削除"]
        XCTAssertTrue(deleteMenuItem.waitForExistence(timeout: 5))
        deleteMenuItem.tap()

        XCTAssertTrue(app.staticTexts["この日の記録を削除しますか？"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '写真アプリ内の写真や動画は削除されません'")
        ).firstMatch.exists)
        XCTAssertTrue(app.buttons["dayDetail.delete.confirm"].exists)
        app.otherElements["PopoverDismissRegion"].tap()
        XCTAssertTrue(app.buttons["dayDetail.mapPreview"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["この日の記録を削除しますか？"].exists)
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
    func testMediaGridPhotoVideoAndUnavailablePreviewFlow() {
        let app = launchMediaDayDetail()
        scrollToMediaGrid(in: app)

        let grid = app.otherElements["dayDetail.media.grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        let cells = app.descendants(matching: .any).matching(
            identifier: "dayDetail.media.cell"
        )
        XCTAssertGreaterThanOrEqual(cells.count, 3)
        XCTAssertEqual(cells.element(boundBy: 0).label, "写真")
        XCTAssertEqual(cells.element(boundBy: 1).label, "動画")

        cells.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["mediaPreview.photo"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.descendants(matching: .any)["mediaPreview.metadata"].exists)
        XCTAssertTrue(app.buttons["mediaPreview.share"].isEnabled)
        app.buttons["BackButton"].tap()

        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        cells.element(boundBy: 1).tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["mediaPreview.video"].waitForExistence(timeout: 5)
        )
        app.buttons["BackButton"].tap()

        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        cells.element(boundBy: 2).tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["mediaPreview.error"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.buttons["再試行"].exists)
    }

    @MainActor
    func testMediaMapClusterAndAnnotationPreviewFlow() {
        let app = launchMediaDayDetail()
        let preview = app.buttons["dayDetail.mapPreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        preview.tap()

        let cluster = app.descendants(matching: .any)["map.mediaCluster"].firstMatch
        XCTAssertTrue(cluster.waitForExistence(timeout: 5))
        XCTAssertTrue(cluster.label.contains("写真と動画"))

        let media = app.descendants(matching: .any)["map.mediaAnnotation"].firstMatch
        XCTAssertTrue(media.waitForExistence(timeout: 5))
        media.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["mediaPreview.photo"].waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testLaunchPerformance() {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func launchMediaDayDetail() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-media")
        app.launch()
        let enabledDay = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'calendar.day.' AND enabled == true")
        ).firstMatch
        XCTAssertTrue(enabledDay.waitForExistence(timeout: 5))
        enabledDay.tap()
        XCTAssertTrue(app.buttons["dayDetail.mapPreview"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func scrollToMediaGrid(in app: XCUIApplication) {
        let grid = app.otherElements["dayDetail.media.grid"]
        for _ in 0 ..< 4 where grid.isHittable == false {
            app.swipeUp()
        }
    }
}
