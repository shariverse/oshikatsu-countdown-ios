//
//  ShareCardUITests.swift
//  OshiConUITests
//

import XCTest

/// 予定の詳細のツールバー → 画像でシェアのプレビュー → 載せる項目の切り替え → シェアのボタンの導線。
///
/// 共有シートは別プロセスの画面なので、シェアのボタンを押せるところまでを確かめる。
/// 写真のある推しは `-useTestPhoto`（テスト用に生成した画像を選ぶ。メモリ上のストアのときだけ効く）で登録する。
final class ShareCardUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useInMemoryStore", "-useTestPhoto", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launchEnvironment = [
            "OSHICON_DEFAULT_hasCompletedOnboarding": "YES",
            "OSHICON_DEFAULT_showsPastEvents": "NO"
        ]
        app.launch()
        return app
    }

    /// 写真のある推しを登録する。
    @MainActor
    private func registerOshiWithPhoto(in app: XCUIApplication) {
        app.selectTab("推し")
        app.navigationBars["推し"].buttons["推しを登録"].tap()
        XCTAssertTrue(app.navigationBars["推しを登録"].waitForExistence(timeout: 5))
        let name = app.textFields["推しの名前"]
        name.tap()
        name.typeText("ミナト\n")
        app.buttons["写真を選ぶ"].tap()
        let done = app.buttons["photoCrop.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()
        XCTAssertTrue(app.buttons["写真を外す"].waitForExistence(timeout: 5))
        app.navigationBars["推しを登録"].buttons["保存"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch.waitForExistence(timeout: 5))
        app.selectTab("ホーム")
    }

    /// 今日の予定を足して詳細を開き、シェアのプレビューを開く。追加の画面は先頭の推しを選んでおく。
    @MainActor
    private func openSharePreview(in app: XCUIApplication, venue: String?) {
        let add = app.buttons["home.addEvent"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        if let venue {
            // キーボードで隠れないよう、下の会場から入れる
            let field = app.textFields["会場・場所（任意）"]
            XCTAssertTrue(field.waitForExistence(timeout: 2))
            field.tap()
            field.typeText(venue)
        }
        let title = app.textFields["タイトル"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        title.tap()
        title.typeText("5th LIVE")
        app.navigationBars["予定を追加"].buttons["保存"].tap()

        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "5th LIVE、")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        let share = app.buttons["eventDetail.share"]
        XCTAssertTrue(share.waitForExistence(timeout: 2))
        share.tap()
        XCTAssertTrue(app.navigationBars["画像でシェア"].waitForExistence(timeout: 2))
    }

    /// カードの見本（読み上げは予定名・日付・日数・会場）。
    @MainActor
    private func preview(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "shareCard.preview", text))
            .firstMatch
    }

    /// 書き出し終えて、シェアのボタンを押せるようになるのを待つ。
    @MainActor
    private func waitForShareButton(in app: XCUIApplication) {
        let button = app.buttons["shareCard.share"]
        XCTAssertTrue(button.waitForExistence(timeout: 2))
        expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: button)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testSharePreviewTogglesVenueAndPhoto() throws {
        let app = launch()
        registerOshiWithPhoto(in: app)
        openSharePreview(in: app, venue: "東京ドーム")

        // 会場は既定で載せない。推しの名前は載せない
        XCTAssertTrue(preview(in: app, containing: "5th LIVE").waitForExistence(timeout: 2))
        XCTAssertTrue(preview(in: app, containing: "今日！").exists)
        XCTAssertFalse(preview(in: app, containing: "東京ドーム").exists)
        XCTAssertFalse(preview(in: app, containing: "ミナト").exists)
        waitForShareButton(in: app)

        // 会場は既定でオフ、写真は既定でオン
        let includesVenue = app.switches["shareCard.includesVenue"]
        let includesPhoto = app.switches["shareCard.includesPhoto"]
        XCTAssertTrue(includesVenue.exists)
        XCTAssertTrue(includesPhoto.exists)
        XCTAssertEqual(includesVenue.value as? String, "0")
        XCTAssertEqual(includesPhoto.value as? String, "1")

        includesVenue.setSwitch(to: "1")
        XCTAssertTrue(preview(in: app, containing: "東京ドーム").waitForExistence(timeout: 2))
        includesPhoto.setSwitch(to: "0")
        waitForShareButton(in: app)

        // 閉じると詳細に戻る
        app.navigationBars["画像でシェア"].buttons["閉じる"].tap()
        XCTAssertTrue(app.buttons["eventDetail.share"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.navigationBars["画像でシェア"].exists)
    }

    @MainActor
    func testSharePreviewHidesTogglesWithoutVenueAndPhoto() throws {
        let app = launch()
        // 推しなし・会場なしの予定では、切り替えを出さずにそのままシェアできる
        openSharePreview(in: app, venue: nil)
        XCTAssertTrue(preview(in: app, containing: "5th LIVE").waitForExistence(timeout: 2))
        XCTAssertFalse(app.switches["shareCard.includesVenue"].exists)
        XCTAssertFalse(app.switches["shareCard.includesPhoto"].exists)
        waitForShareButton(in: app)
    }
}
