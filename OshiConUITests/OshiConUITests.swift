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

    @MainActor
    func testRegisterEditAndDeleteOshi() throws {
        let app = launch(hasCompletedOnboarding: true)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["推し"].tap()
        XCTAssertTrue(app.staticTexts["推しを登録しよう"].waitForExistence(timeout: 2))

        // 登録する
        app.navigationBars["推し"].buttons["推しを登録"].tap()
        XCTAssertTrue(app.navigationBars["推しを登録"].waitForExistence(timeout: 2))
        let save = app.navigationBars["推しを登録"].buttons["保存"]
        XCTAssertFalse(save.isEnabled)
        let name = app.textFields["推しの名前"]
        name.tap()
        name.typeText("ミナト")
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch.waitForExistence(timeout: 2))
        // 行は名前と予定の件数をまとめて読み上げる
        XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "予定 0 件")).firstMatch.exists)

        // 編集して名前を変える
        app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["推しを編集"].waitForExistence(timeout: 2))
        let editingName = app.textFields["推しの名前"]
        editingName.tap()
        editingName.typeText("くん")
        app.navigationBars["推しを編集"].buttons["保存"].tap()
        let renamed = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "ミナトくん")).firstMatch
        XCTAssertTrue(renamed.waitForExistence(timeout: 2))

        // 削除する
        renamed.tap()
        XCTAssertTrue(app.navigationBars["推しを編集"].waitForExistence(timeout: 2))
        app.buttons["推しを削除"].tap()
        let alert = app.alerts["「ミナトくん」を削除しますか？"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        XCTAssertTrue(alert.staticTexts["元に戻せません。"].exists)
        alert.buttons["削除"].tap()
        XCTAssertTrue(app.staticTexts["推しを登録しよう"].waitForExistence(timeout: 2))
    }
}
