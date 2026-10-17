//
//  AppStoreScreenshotTests.swift
//  OshiConUITests
//

import XCTest

/// App Store 用スクリーンショットを撮る。見本の推しと予定（`-seedSampleData`）で起動し、主要な画面を添付ファイルとして残す。
///
/// ふだんのテストでは流さない。`scripts/app-store-screenshots.sh` が環境変数 `APP_STORE_SCREENSHOTS=1`
/// （xcodebuild には `TEST_RUNNER_APP_STORE_SCREENSHOTS=1` で渡す）を付けて、6.9 インチの iPhone と 13 インチの iPad で流す。
final class AppStoreScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["APP_STORE_SCREENSHOTS"] == "1",
            "App Store 用スクリーンショットは scripts/app-store-screenshots.sh で撮る"
        )
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-hasCompletedOnboarding", "YES",
            "-showsPastEvents", "NO"
        ]
        app.launch()

        // 1. ホーム（先頭のピン留めのライブと、これからの予定）
        let featured = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "ピン留め")).firstMatch
        XCTAssertTrue(featured.waitForExistence(timeout: 5))
        capture("01-ホーム")

        // 2. 予定の詳細（秒単位のカウントダウンと進み具合）
        featured.tap()
        XCTAssertTrue(app.buttons["ピン留めを外す"].waitForExistence(timeout: 3))
        capture("02-予定の詳細")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(featured.waitForExistence(timeout: 3))

        // 3. 予定の追加
        app.navigationBars["推し活カウントダウン"].buttons["予定を追加"].tap()
        let title = app.textFields["タイトル"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap()
        title.typeText("3rd アルバム発売記念イベント")
        capture("03-予定の追加")
        app.navigationBars["予定を追加"].buttons["キャンセル"].tap()
        XCTAssertTrue(featured.waitForExistence(timeout: 3))

        // 4. 推しの一覧
        openSection("推し", in: app)
        XCTAssertTrue(app.navigationBars["推し"].waitForExistence(timeout: 3))
        capture("04-推し")
    }

    /// iPhone はタブバー、iPad はサイドバーで切り替える。
    @MainActor
    private func openSection(_ title: String, in app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons[title].tap()
        } else {
            app.collectionViews.staticTexts[title].firstMatch.tap()
        }
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
