import XCTest

final class DriveLogMemoryPerformanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMapAndGridMemoryPerformance() {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTMemoryMetric()], options: options) {
            let app = XCUIApplication()
            app.launchArguments.append("-ui-testing-media")
            app.launch()
            let day = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH 'calendar.day.' AND enabled == true")
            ).firstMatch
            XCTAssertTrue(day.waitForExistence(timeout: 5))
            day.tap()
            let map = app.buttons["dayDetail.mapPreview"]
            XCTAssertTrue(map.waitForExistence(timeout: 5))
            let grid = app.otherElements["dayDetail.media.grid"]
            for _ in 0 ..< 4 where grid.isHittable == false {
                app.swipeUp()
            }
            XCTAssertTrue(grid.exists)
            map.tap()
            XCTAssertTrue(
                app.descendants(matching: .any)["map.mediaCluster"].waitForExistence(timeout: 5)
            )
            app.terminate()
        }
    }
}
