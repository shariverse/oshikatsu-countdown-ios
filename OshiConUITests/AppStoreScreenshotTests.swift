//
//  AppStoreScreenshotTests.swift
//  OshiConUITests
//

import XCTest

/// App Store 用スクリーンショットを撮る。見本の推しと予定（`-seedSampleData`）で起動し、主要な画面を添付ファイルとして残す。
///
/// ふだんのテストでは流さない。`scripts/app-store-screenshots.sh` が環境変数 `APP_STORE_SCREENSHOTS=1`
/// （xcodebuild には `TEST_RUNNER_APP_STORE_SCREENSHOTS=1` で渡す）を付けて、6.9 インチの iPhone と 13 インチの iPad で流す。
/// 戻るボタンやサイドバーの並びは iPhone と iPad で違うので、画面ごとに起動し直してから開く。
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
        // 1. ホーム（先頭のピン留めのライブと、これからの予定）
        var app = launch()
        let featured = featuredCard(in: app)
        XCTAssertTrue(featured.waitForExistence(timeout: 5))
        capture("01-ホーム")

        // 2. 予定の詳細（秒単位のカウントダウンと進み具合）
        featured.tap()
        XCTAssertTrue(app.buttons["ピン留めを外す"].waitForExistence(timeout: 3))
        capture("02-予定の詳細")

        // 3. 予定の追加
        app = launch()
        XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: 5))
        app.buttons["予定を追加"].firstMatch.tap()
        let title = app.textFields["タイトル"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap()
        title.typeText("3rd アルバム発売記念イベント")
        capture("03-予定の追加")

        // 4. 推しの一覧
        app = launch()
        XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: 5))
        openSection("推し", in: app)
        XCTAssertTrue(app.staticTexts["LUMINA"].firstMatch.waitForExistence(timeout: 3))
        capture("04-推し")
    }

    /// 見本のデータで起動し直す。キーボードやシステムの文言が日本語になるよう、言語と地域も日本にする。
    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.terminate()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-hasCompletedOnboarding", "YES",
            "-showsPastEvents", "NO",
            "-AppleLanguages", "(ja)",
            "-AppleLocale", "ja_JP"
        ]
        app.launch()
        return app
    }

    /// 先頭のカード（読み上げは「ピン留め、…」で始まるリンク）。詳細の「ピン留めを外す」と取り違えないよう読点まで見る。
    @MainActor
    private func featuredCard(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "ピン留め、")).firstMatch
    }

    /// iPhone はタブバー、iPad はサイドバーで切り替える。サイドバーが隠れていたら出してから押す。
    @MainActor
    private func openSection(_ title: String, in app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons[title].tap()
            return
        }
        let item = app.collectionViews.staticTexts[title].firstMatch
        if !item.exists || !item.isHittable {
            let toggle = app.buttons.matching(
                NSPredicate(format: "identifier == %@ OR label CONTAINS %@", "ToggleSidebar", "サイドバー")
            ).firstMatch
            if toggle.exists {
                toggle.tap()
            }
        }
        XCTAssertTrue(item.waitForExistence(timeout: 3))
        item.tap()
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
