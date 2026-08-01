import XCTest

final class July17MapBackUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDenseMapKeepsSingleBackControlVisible() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-july-17-map")
        app.launch()

        let july17 = app.buttons["calendar.day.2026-7-17"]
        XCTAssertTrue(july17.waitForExistence(timeout: 5))
        XCTAssertTrue(july17.isEnabled)
        july17.tap()

        let preview = app.buttons["dayDetail.mapPreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        preview.tap()

        let backButtons = app.buttons.matching(identifier: "map.back")
        let back = backButtons.firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        assertVisible(back, count: backButtons.count, in: app)

        let movement = app.descendants(matching: .any)["map.polyline"].firstMatch
        XCTAssertTrue(movement.waitForExistence(timeout: 5))
        movement.tap()
        assertVisible(back, count: backButtons.count, in: app)

        let stay = app.descendants(matching: .any)["map.placeStayControl"].firstMatch
        XCTAssertTrue(stay.waitForExistence(timeout: 5))
        stay.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["map.placeSheet"].firstMatch
                .waitForExistence(timeout: 5)
        )
        app.buttons["地図に戻る"].tap()
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        assertVisible(back, count: backButtons.count, in: app)

        back.tap()
        let currentDate = app.descendants(matching: .any)["dayDetail.currentDate"]
        XCTAssertTrue(currentDate.waitForExistence(timeout: 5))
        XCTAssertEqual(currentDate.label, "2026-07-17")
    }

    private func assertVisible(_ back: XCUIElement, count: Int, in app: XCUIApplication) {
        XCTAssertEqual(count, 1)
        XCTAssertTrue(back.isHittable)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(back.frame))
    }
}
