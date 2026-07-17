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
    func testCalendarUsesContinuousVerticalScroll() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-calendar")
        app.launch()

        let scroll = app.scrollViews["calendar.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.otherElements.matching(
                NSPredicate(format: "identifier BEGINSWITH 'calendar.month.'")
            ).firstMatch.waitForExistence(timeout: 5)
        )
        scroll.swipeUp()
        XCTAssertTrue(scroll.exists)
    }

    @MainActor
    func testOnboardingContentAndStartFlow() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-onboarding")
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["onboarding.root"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["DriveLog"].exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS '位置情報'")
        ).firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS 'モーション'")
        ).firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS '写真と動画'")
        ).firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS '外部サーバーへ送信されません'")
        ).firstMatch.exists)
        XCTAssertTrue(app.buttons["onboarding.start"].isEnabled)
    }

    @MainActor
    func testOnboardingPermissionFlowReachesCalendar() {
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
        XCTAssertTrue(app.scrollViews["calendar.scroll"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["onboarding.root"].exists)
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
        let currentDate = app.descendants(matching: .any)["dayDetail.currentDate"]
        XCTAssertTrue(currentDate.waitForExistence(timeout: 5))
        let initialDate = currentDate.label
        let pager = app.descendants(matching: .any)["dayDetail.pager"]
        XCTAssertTrue(pager.exists)
        pager.swipeLeft()
        XCTAssertNotEqual(currentDate.label, initialDate)
        app.swipeDown()
        XCTAssertTrue(app.scrollViews["calendar.scroll"].waitForExistence(timeout: 5))
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
    func testDayDeletionReturnsToCalendarAndRemovesDistance() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-day-detail")
        app.launch()

        let enabledDay = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'calendar.day.' AND enabled == true")
        ).firstMatch
        XCTAssertTrue(enabledDay.waitForExistence(timeout: 5))
        let dayIdentifier = enabledDay.identifier
        enabledDay.tap()
        let menu = app.buttons["dayDetail.menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["この日の記録を削除"].tap()
        let confirm = app.buttons["dayDetail.delete.confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        XCTAssertTrue(app.scrollViews["calendar.scroll"].waitForExistence(timeout: 5))
        let deletedDay = app.buttons[dayIdentifier]
        XCTAssertTrue(deletedDay.exists)
        XCTAssertFalse(deletedDay.isEnabled)
        XCTAssertFalse(deletedDay.label.contains("移動距離"))
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

        let back = app.buttons["map.back"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["map.currentLocation"].exists)
        let movement = app.descendants(matching: .any)["map.polyline"].firstMatch
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
            app.descendants(matching: .any)["map.placeSheet"].firstMatch
                .waitForExistence(timeout: 5)
        )
        app.buttons["地図に戻る"].tap()

        back.tap()
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
        app.swipeLeft()
        XCTAssertTrue(
            app.descendants(matching: .any)["mediaPreview.video"].waitForExistence(timeout: 5)
        )
        app.swipeLeft()
        XCTAssertTrue(
            app.descendants(matching: .any)["mediaPreview.error"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.buttons["再試行"].exists)
        XCTAssertTrue(app.buttons["mediaPreview.back"].exists)
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
        XCTAssertTrue(cluster.label.contains("滞在"))
        cluster.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["map.placeSheet"].waitForExistence(timeout: 5)
        )
        let media = app.descendants(matching: .any).matching(
            identifier: "dayDetail.media.cell"
        )
        XCTAssertEqual(media.count, 2)
        XCTAssertFalse(app.buttons["修正"].exists)
        media.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["mediaPreview.photo"].waitForExistence(timeout: 5)
        )
        app.swipeLeft()
        XCTAssertTrue(
            app.descendants(matching: .any)["mediaPreview.video"].waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testLaunchPerformance() {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

private extension DriveLogUITests {
    @MainActor
    func launchMediaDayDetail() -> XCUIApplication {
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
    func scrollToMediaGrid(in app: XCUIApplication) {
        let grid = app.otherElements["dayDetail.media.grid"]
        for _ in 0 ..< 4 where grid.isHittable == false {
            app.swipeUp()
        }
    }

    @MainActor
    func tap(_ button: XCUIElement, expectingLabel label: String) {
        expectation(for: NSPredicate(format: "label == %@", label), evaluatedWith: button)
        waitForExpectations(timeout: 5)
        button.tap()
    }
}
