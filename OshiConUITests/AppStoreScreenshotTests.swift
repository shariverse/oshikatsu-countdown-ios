//
//  AppStoreScreenshotTests.swift
//  OshiConUITests
//

import XCTest

/// App Store 用スクリーンショットを撮る。見本の推しと予定（`-seedSampleData`）で起動し、主要な画面を添付ファイルとして残す。
///
/// ふだんのテストでは流さない。`scripts/app-store-screenshots.sh` が環境変数 `APP_STORE_SCREENSHOTS=1`
/// （xcodebuild には `TEST_RUNNER_APP_STORE_SCREENSHOTS=1` で渡す）を付けて、表示サイズ・言語ごとに流す。
/// 言語は `APP_STORE_LANGUAGE`（`-AppleLanguages` の値）と `APP_STORE_LOCALE`（`-AppleLocale` の値）で受け取る。
/// 文言は言語で変わるので、要素はアクセシビリティ ID と並びの位置で探す。
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
        XCTAssertTrue(app.buttons["eventDetail.pin"].waitForExistence(timeout: 5))
        capture("02-予定の詳細")

        // 3. 予定の追加
        app = launch()
        XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: 5))
        app.buttons["home.addEvent"].firstMatch.tap()
        let title = app.textFields["eventEditor.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        // 日本語の入力では確定前の文字が残って写るので、英数字だけのタイトルにする
        title.typeText("3rd ALBUM Release Party")
        capture("03-予定の追加")

        // 4. 推しの一覧
        app = launch()
        XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: 5))
        openSection(.oshi, in: app)
        XCTAssertTrue(app.buttons["oshiList.row"].firstMatch.waitForExistence(timeout: 5))
        capture("04-推し")
    }

    /// 見本のデータで起動し直す（動いていれば終わらせてから起動する）。システムの文言もその言語になるよう、言語と地域も渡す。
    @MainActor
    private func launch() -> XCUIApplication {
        let environment = ProcessInfo.processInfo.environment
        let language = environment["APP_STORE_LANGUAGE"] ?? "ja"
        let locale = environment["APP_STORE_LOCALE"] ?? "ja_JP"
        let app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-hasCompletedOnboarding", "YES",
            "-showsPastEvents", "NO",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale
        ]
        app.launch()
        return app
    }

    /// 先頭のカード（ピン留めした予定へのリンク）。
    @MainActor
    private func featuredCard(in app: XCUIApplication) -> XCUIElement {
        app.buttons["home.featuredEvent"].firstMatch
    }

    /// タブ（並びは AppTab と同じ）。
    private enum Section: Int {
        case home
        case oshi
        case settings
    }

    /// iPhone はタブバー、iPad・iPhone Duo はサイドバーで切り替える。サイドバーが隠れていたら出してから押す。
    @MainActor
    private func openSection(_ section: Section, in app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons.element(boundBy: section.rawValue).tap()
            return
        }
        if sidebarItem(section, in: app) == nil {
            let toggle = app.buttons["ToggleSidebar"].firstMatch
            if toggle.exists {
                toggle.tap()
            }
        }
        // サイドバーの項目の要素の種類は OS や機種で変わる（iOS 26 の iPad は collection view のセルで、行に付けた ID が届かない）
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if let item = sidebarItem(section, in: app) {
                item.tap()
                return
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        // 見つからなかったときは、次に直せるよう画面の要素の一覧をログに残す
        print(app.debugDescription)
        XCTFail("サイドバーの項目 \(section) が見つかりません")
    }

    /// サイドバーの項目。ID、並びの位置（collection view・table・outline のセル）の順に探し、押せるものを返す。
    @MainActor
    private func sidebarItem(_ section: Section, in app: XCUIApplication) -> XCUIElement? {
        let candidates = [
            app.descendants(matching: .any)["sidebar.\(section)"].firstMatch,
            app.collectionViews.firstMatch.cells.element(boundBy: section.rawValue),
            app.tables.firstMatch.cells.element(boundBy: section.rawValue),
            app.outlines.firstMatch.cells.element(boundBy: section.rawValue)
        ]
        return candidates.first { $0.exists && $0.isHittable }
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
