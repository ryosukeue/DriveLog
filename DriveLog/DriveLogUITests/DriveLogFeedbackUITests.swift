import XCTest

final class DriveLogFeedbackUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEmptyCalendarShowsOneMonthlyEmptyState() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-calendar")
        app.launch()

        let emptyState = app.staticTexts["この月の移動記録はありません"]
        for _ in 0 ..< 3 where emptyState.waitForExistence(timeout: 1) == false {
            app.swipeUp()
        }
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["calendar.empty"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["calendar.monthlyOverview.empty"].exists)
    }

    @MainActor
    func testMonthlyGalleryPreviewHasWorkingBackButton() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-july-17-map")
        app.launch()

        let gallery = app.descendants(matching: .any)["calendar.monthlyGallery"]
        for _ in 0 ..< 6 where gallery.waitForExistence(timeout: 1) == false {
            app.swipeUp()
        }
        XCTAssertTrue(gallery.waitForExistence(timeout: 5))
        let mediaCell = app.buttons["写真"].firstMatch
        for _ in 0 ..< 3 where mediaCell.isHittable == false {
            app.swipeUp()
        }
        XCTAssertTrue(mediaCell.waitForExistence(timeout: 5))
        XCTAssertTrue(mediaCell.isHittable)
        mediaCell.tap()

        let back = app.buttons["mediaPreview.back"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertTrue(back.isHittable)
        back.tap()
        XCTAssertTrue(gallery.waitForExistence(timeout: 5))
    }

    @MainActor
    func testMonthlyMapMediaPreviewDismissesMapBeforeOpening() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-july-17-map")
        app.launch()

        let map = app.descendants(matching: .any)["calendar.monthlyMap"]
        for _ in 0 ..< 5 where map.waitForExistence(timeout: 1) == false {
            app.swipeUp()
        }
        XCTAssertTrue(map.waitForExistence(timeout: 5))
        map.tap()

        let mediaAnnotation = app.descendants(matching: .any)["map.placeMediaControl"].firstMatch
        XCTAssertTrue(mediaAnnotation.waitForExistence(timeout: 5))
        mediaAnnotation.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["map.placeSheet"].waitForExistence(timeout: 5)
        )
        let media = app.descendants(matching: .any).matching(
            identifier: "dayDetail.media.cell"
        ).firstMatch
        XCTAssertTrue(media.waitForExistence(timeout: 5))
        media.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["mediaPreview.photo"].waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.buttons["map.back"].exists)
        let back = app.buttons["mediaPreview.back"]
        XCTAssertTrue(back.isHittable)
        back.tap()
        XCTAssertTrue(map.waitForExistence(timeout: 5))
    }
}
