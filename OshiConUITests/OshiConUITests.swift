//
//  OshiConUITests.swift
//  OshiConUITests
//
//  Created by 村石 拓海 on 2024/05/12.
//

import XCTest

final class OshiConUITests: XCTestCase {
    override func setUpWithError() throws {
        // UI テストでは失敗した時点で即座に止める
        continueAfterFailure = false
    }

    /// 端末に残ったデータに左右されないよう、メモリ上のストアで起動する。
    @MainActor
    private func launch(hasCompletedOnboarding: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useInMemoryStore", "-hasCompletedOnboarding", hasCompletedOnboarding ? "YES" : "NO"]
        app.launch()
        return app
    }

    @MainActor
    func testFirstLaunchShowsOnboarding() throws {
        let app = launch(hasCompletedOnboarding: false)
        XCTAssertTrue(app.buttons["はじめる"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }

    @MainActor
    func testTabsSwitchBetweenHomeOshiAndSettings() throws {
        let app = launch(hasCompletedOnboarding: true)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["推し活カウントダウン"].exists)

        tabBar.buttons["推し"].tap()
        XCTAssertTrue(app.navigationBars["推し"].waitForExistence(timeout: 2))

        tabBar.buttons["設定"].tap()
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 2))

        tabBar.buttons["ホーム"].tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン"].waitForExistence(timeout: 2))
    }
}
