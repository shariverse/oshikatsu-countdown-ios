//
//  PhotoCropUITests.swift
//  OshiConUITests
//

import XCTest

/// 推しの写真を選ぶ → 調整画面 → 保存の導線。
///
/// `PhotosPicker` は別プロセスの画面で操作できないので、`-useTestPhoto` で「写真を選ぶ」をテスト用に生成した画像を選ぶボタンに替える
/// （`LaunchOptions.usesTestPhoto`。メモリ上のストアのときだけ効く）。
final class PhotoCropUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(hasCompletedOnboarding: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useInMemoryStore", "-useTestPhoto", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launchEnvironment = [
            "OSHICON_DEFAULT_hasCompletedOnboarding": hasCompletedOnboarding ? "YES" : "NO",
            "OSHICON_DEFAULT_showsPastEvents": "NO"
        ]
        app.launch()
        return app
    }

    /// 調整画面の見出し。
    @MainActor
    private func cropTitle(in app: XCUIApplication) -> XCUIElement {
        app.staticTexts["移動と拡大・縮小"]
    }

    @MainActor
    func testOnboardingPickPhotoShowsCropScreenAndCancelKeepsNoPhoto() throws {
        let app = launch(hasCompletedOnboarding: false)
        XCTAssertTrue(app.navigationBars["ステップ 1 / 2"].waitForExistence(timeout: 5))

        app.buttons["写真を選ぶ"].tap()
        XCTAssertTrue(cropTitle(in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["完了"].exists)

        // 「やめる」で、写真を選ぶ前（写真なし）に戻る
        app.buttons["やめる"].tap()
        XCTAssertTrue(app.navigationBars["ステップ 1 / 2"].waitForExistence(timeout: 5))
        XCTAssertFalse(cropTitle(in: app).exists)
        XCTAssertTrue(app.buttons["写真を選ぶ"].exists)
        XCTAssertFalse(app.buttons["写真を外す"].exists)
    }

    @MainActor
    func testCropAndSaveShowsPhotoThenCancelKeepsIt() throws {
        let app = launch(hasCompletedOnboarding: true)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["推し"].tap()
        app.navigationBars["推し"].buttons["推しを登録"].tap()
        XCTAssertTrue(app.navigationBars["推しを登録"].waitForExistence(timeout: 2))
        let name = app.textFields["推しの名前"]
        name.tap()
        name.typeText("ミナト")

        // 写真を選ぶと調整画面が出る。ピンチで拡大してから「完了」
        app.buttons["写真を選ぶ"].tap()
        XCTAssertTrue(cropTitle(in: app).waitForExistence(timeout: 5))
        let photo = app.descendants(matching: .any)["調整中の写真"]
        XCTAssertTrue(photo.exists)
        let before = photo.value as? String
        photo.pinch(withScale: 2, velocity: 1)
        // 指を離したあとの補正のアニメーションを待つ
        let deadline = Date().addingTimeInterval(5)
        while photo.value as? String == before, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertNotEqual(photo.value as? String, before)
        app.buttons["完了"].tap()

        // 調整した写真がプレビューに入り、「写真を変える」「写真を外す」になる
        XCTAssertTrue(app.buttons["写真を外す"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["写真を変える"].exists)
        app.navigationBars["推しを登録"].buttons["保存"].tap()

        // 保存した推しを開き直すと、保存した写真がある
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["推しを編集"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["写真を外す"].waitForExistence(timeout: 5))

        // 写真を選び直して「やめる」と、前の写真のまま
        app.buttons["写真を変える"].tap()
        XCTAssertTrue(cropTitle(in: app).waitForExistence(timeout: 5))
        app.buttons["やめる"].tap()
        XCTAssertTrue(app.navigationBars["推しを編集"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["写真を外す"].waitForExistence(timeout: 5))

        // 保存してある写真から「位置を調整」で開き直し、何も変えずに「完了」しても写真はそのまま
        app.buttons["位置を調整"].tap()
        XCTAssertTrue(cropTitle(in: app).waitForExistence(timeout: 5))
        app.buttons["完了"].tap()
        XCTAssertTrue(app.navigationBars["推しを編集"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["写真を外す"].waitForExistence(timeout: 5))

        // 写真を外したあとに選んで「やめる」と、写真なしのまま
        app.buttons["写真を外す"].tap()
        XCTAssertTrue(app.buttons["写真を選ぶ"].waitForExistence(timeout: 2))
        app.buttons["写真を選ぶ"].tap()
        XCTAssertTrue(cropTitle(in: app).waitForExistence(timeout: 5))
        app.buttons["やめる"].tap()
        XCTAssertTrue(app.buttons["写真を選ぶ"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["写真を外す"].exists)
    }
}
