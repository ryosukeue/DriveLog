import XCTest

final class RecordingStartUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingPermissionFlowReachesRecordingHomeAndCalendar() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-onboarding-flow")
        app.launch()

        let action = app.buttons["onboarding.start"]
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        tap(action, expectingLabel: "位置情報の設定を始める")
        tap(action, expectingLabel: "「常に許可」の設定へ進む")
        tap(action, expectingLabel: "モーションの利用を許可する")
        tap(action, expectingLabel: "次へ")
        tap(action, expectingLabel: "写真と動画の利用を許可する")

        let limitedPhotos = app.descendants(matching: .any)["onboarding.limitedPhotosMessage"]
        XCTAssertTrue(limitedPhotos.waitForExistence(timeout: 5))
        if app.buttons["onboarding.changePhotoSelection"].isHittable == false {
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons["onboarding.changePhotoSelection"].exists)
        tap(action, expectingLabel: "DriveLogを始める")

        XCTAssertTrue(app.descendants(matching: .any)["recordingStart.root"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["記録開始"].exists)
        XCTAssertTrue(app.buttons["移動記録を参照"].exists)
        app.buttons["移動記録を参照"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["calendar.pager"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["onboarding.root"].exists)
    }

    @MainActor
    func testRecordingStartHomeSwitchesToHighDensityStateAndBrowse() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-recording-start")
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["recordingStart.root"].waitForExistence(timeout: 5))
        let start = app.buttons["記録開始"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        let recordingState = app.buttons["記録中"]
        XCTAssertTrue(recordingState.waitForExistence(timeout: 5))
        XCTAssertEqual(recordingState.label, "記録中")
        app.buttons["移動記録を参照"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["calendar.pager"].waitForExistence(timeout: 5))
    }
}

private extension RecordingStartUITests {
    @MainActor
    func tap(_ button: XCUIElement, expectingLabel label: String) {
        XCTAssertEqual(button.label, label)
        button.tap()
    }
}
