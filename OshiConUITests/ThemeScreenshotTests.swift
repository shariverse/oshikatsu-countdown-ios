//
//  ThemeScreenshotTests.swift
//  OshiConUITests
//

import XCTest

/// テーマ案の見本のアプリの画面を撮る（README の「テーマの見本」）。見本の推しと予定で、DEBUG の起動引数 `-previewTheme` のテーマで起動する。
///
/// ふだんのテストでは流さない。環境変数 `THEME_SCREENSHOTS=1`（xcodebuild には `TEST_RUNNER_THEME_SCREENSHOTS=1`）のときだけ流れ、
/// テーマは `THEME_ID`（`AppTheme` の id。無ければ標準のテーマ）で選ぶ。ライト / ダークは Simulator の外観に合わせる。
/// ウィジェットは `ThemeWidgetScreenshotTests`（Unit テスト）が撮る。
final class ThemeScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["THEME_SCREENSHOTS"] == "1",
            "テーマの見本は README の「テーマの見本」の手順で撮る"
        )
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureThemeScreens() throws {
        // 1. ホーム（先頭のピン留めのライブと、これからの予定）
        var app = launch()
        let featured = app.buttons["home.featuredEvent"].firstMatch
        XCTAssertTrue(featured.waitForExistence(timeout: 5))
        capture("01-ホーム")

        // 2. 予定の詳細
        featured.tap()
        XCTAssertTrue(app.buttons["eventDetail.pin"].waitForExistence(timeout: 5))
        capture("02-予定の詳細")

        // 3. 予定の追加
        app = launch()
        XCTAssertTrue(app.buttons["home.featuredEvent"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["home.addEvent"].firstMatch.tap()
        let title = app.textFields["eventEditor.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        // 日本語の入力では確定前の文字が残って写るので、英数字だけのタイトルにする
        title.typeText("3rd ALBUM Release Party")
        capture("03-予定の追加")
    }

    /// 見本のデータとテーマで起動し直す（動いていれば終わらせてから起動する）。
    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-hasCompletedOnboarding", "YES",
            "-showsPastEvents", "NO",
            "-AppleLanguages", "(ja)",
            "-AppleLocale", "ja_JP",
            "-previewTheme", ProcessInfo.processInfo.environment["THEME_ID"] ?? "standard"
        ]
        app.launch()
        return app
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
