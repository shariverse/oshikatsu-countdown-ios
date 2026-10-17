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
        XCTAssertTrue(app.navigationBars["ステップ 1 / 2"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }

    @MainActor
    func testOnboardingRegistersOshiAndFirstEvent() throws {
        let app = launch(hasCompletedOnboarding: false)
        XCTAssertTrue(app.navigationBars["ステップ 1 / 2"].waitForExistence(timeout: 5))
        let next = app.buttons["次へ：最初の予定を登録"]
        XCTAssertFalse(next.isEnabled)
        let name = app.textFields["推しの名前"]
        name.tap()
        name.typeText("ミナト")
        next.tap()

        // 2 歩目では、登録したばかりの推しを選んでおく
        XCTAssertTrue(app.navigationBars["ステップ 2 / 2"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch.exists)
        let start = app.buttons["保存してはじめる"]
        XCTAssertFalse(start.isEnabled)
        let title = app.textFields["タイトル"]
        title.tap()
        title.typeText("5th LIVE")
        start.tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 2))
    }

    @MainActor
    func testOnboardingCanBeSkipped() throws {
        let app = launch(hasCompletedOnboarding: false)
        XCTAssertTrue(app.navigationBars["ステップ 1 / 2"].waitForExistence(timeout: 5))
        app.navigationBars["ステップ 1 / 2"].buttons["あとで"].tap()
        XCTAssertTrue(app.navigationBars["ステップ 2 / 2"].waitForExistence(timeout: 2))
        app.navigationBars["ステップ 2 / 2"].buttons["あとで"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 2))
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
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch.waitForExistence(timeout: 2))
        // 行は名前と予定の件数をまとめて読み上げる
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "予定 0 件")).firstMatch.exists)

        // 編集して名前を変える
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["推しを編集"].waitForExistence(timeout: 2))
        let editingName = app.textFields["推しの名前"]
        editingName.tap()
        editingName.typeText("くん")
        app.navigationBars["推しを編集"].buttons["保存"].tap()
        let renamed = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナトくん")).firstMatch
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

    @MainActor
    func testSettingsShowsPastEventsToggleAndLicenses() throws {
        let app = launch(hasCompletedOnboarding: true)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["設定"].tap()
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 2))

        let showsPast = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "終わった予定も表示する")).firstMatch
        XCTAssertTrue(showsPast.exists)
        XCTAssertEqual(showsPast.value as? String, "0")
        XCTAssertTrue(app.staticTexts["バージョン"].exists)

        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "オープンソースライセンス")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["オープンソースライセンス"].waitForExistence(timeout: 2))
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Outfit")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Outfit"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "SIL OPEN FONT LICENSE")).firstMatch.exists)
    }

    @MainActor
    func testAddEventFromHome() throws {
        let app = launch(hasCompletedOnboarding: true)
        XCTAssertTrue(app.staticTexts["まだ予定がありません"].waitForExistence(timeout: 5))

        app.navigationBars["推し活カウントダウン"].buttons["予定を追加"].tap()
        XCTAssertTrue(app.navigationBars["予定を追加"].waitForExistence(timeout: 2))
        let save = app.navigationBars["予定を追加"].buttons["保存"]
        XCTAssertFalse(save.isEnabled)
        let title = app.textFields["タイトル"]
        title.tap()
        title.typeText("5th LIVE")
        XCTAssertTrue(save.isEnabled)
        save.tap()

        // 今日の予定なので、先頭のカードと、これからの予定の行に「今日！」で出る
        let featured = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "いちばん近い予定")).firstMatch
        XCTAssertTrue(featured.waitForExistence(timeout: 2))
        XCTAssertTrue(featured.label.contains("5th LIVE"))
        XCTAssertTrue(featured.label.contains("今日！"))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "5th LIVE、")).firstMatch.exists)
    }
}
