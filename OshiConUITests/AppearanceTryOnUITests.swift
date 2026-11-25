//
//  AppearanceTryOnUITests.swift
//  OshiConUITests
//

import XCTest

/// 着せ替えの画面の見本の切り替え（ホーム・予定の詳細・シェア。下の切り替えと横のスワイプ）と、全画面の試着の導線。
/// 起動と操作は `AppearanceUITestCase`。
final class AppearanceTryOnUITests: AppearanceUITestCase {
    /// 見本を、下の切り替えと横のスワイプで、ホーム・予定の詳細・シェアのカードに替えられる。選んだ写真は、どの見本にも映る。
    @MainActor
    func testPreviewSwitchesBetweenHomeDetailAndShare() throws {
        let app = launchSettings(arguments: ["-plusLocked", "-seedSampleData"])
        openAppearance(in: app)
        let home = app.buttons["appearance.previewKind.home"]
        let detail = app.buttons["appearance.previewKind.eventDetail"]
        let share = app.buttons["appearance.previewKind.share"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        waitForPreviewLabel("ホームの見本", in: app)
        XCTAssertTrue(home.isSelected)

        // 下の切り替えで替える。シェアのカードは背景の写真だけを地に使うので、写真があるかだけを伝える
        detail.tap()
        waitForPreviewLabel("予定の詳細の見本", in: app)
        waitForPreview(in: app, containing: ["背景の写真なし", "推しの写真の飾りなし"])
        XCTAssertTrue(detail.isSelected)
        share.tap()
        waitForPreviewLabel("シェアのカードの見本", in: app)
        XCTAssertEqual(preview(in: app).value as? String, "背景の写真なし")
        XCTAssertTrue(share.isSelected)

        // 横のスワイプで、となりの見本に替える（切り替えの選択も付いてくる）
        preview(in: app).swipeRight()
        waitForPreviewLabel("予定の詳細の見本", in: app)
        XCTAssertTrue(detail.isSelected)
        preview(in: app).swipeLeft()
        waitForPreviewLabel("シェアのカードの見本", in: app)
        XCTAssertTrue(share.isSelected)

        // 写真を選ぶと、シェアのカードの見本にも、予定の詳細の見本にも映る
        pickAndCropPhoto(in: app)
        waitForPreviewLabel("シェアのカードの見本", in: app)
        let shown = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "背景の写真あり"), object: preview(in: app))
        _ = XCTWaiter().wait(for: [shown], timeout: 5)
        XCTAssertEqual(preview(in: app).value as? String, "背景の写真あり")
        detail.tap()
        waitForPreviewLabel("予定の詳細の見本", in: app)
        waitForPreview(in: app, containing: ["背景の写真あり", "暗幕の濃さ 50%", "ぼかしの強さ 40%", "推しの写真の飾りなし"])
        // 設定を変えている間も、見本は画面の中にある
        assertPreviewVisible(besides: app.buttons["appearance.selectPhoto"], in: app)
    }

    /// 全画面の試着: 「全画面」で見本を画面いっぱいに出し、見本を切り替え、長押しで着せ替える前と比べ、「Plus で使う」から課金画面を開ける。
    @MainActor
    func testFullScreenTryOn() throws {
        let app = launchSettings(arguments: ["-plusLocked", "-seedSampleData"])
        openAppearance(in: app)
        pickAndCropPhoto(in: app)
        waitForPreview(in: app, containing: ["背景の写真あり", "暗幕の濃さ 50%", "ぼかしの強さ 40%"])
        app.buttons["appearance.previewKind.eventDetail"].tap()
        waitForPreviewLabel("予定の詳細の見本", in: app)

        // 着せ替えの画面で映していた見本のまま、全画面で出す
        app.buttons["appearance.fullScreen"].tap()
        let tryOn = app.descendants(matching: .any)["appearance.tryOn.preview"].firstMatch
        waitForPreviewLabel("予定の詳細の見本", of: "appearance.tryOn.preview", in: app)
        XCTAssertEqual(tryOn.value as? String, "背景の写真あり、暗幕の濃さ 50%、ぼかしの強さ 40%、推しの写真の飾りなし")
        XCTAssertTrue(app.buttons["appearance.tryOn.close"].exists)
        XCTAssertTrue(app.buttons["appearance.tryOn.openPaywall"].exists)

        // 全画面でも見本を切り替えられる（下に残る着せ替えの画面の切り替えとは、identifier を分けている）
        app.buttons["appearance.tryOn.previewKind.share"].tap()
        waitForPreviewLabel("シェアのカードの見本", of: "appearance.tryOn.preview", in: app)
        XCTAssertEqual(tryOn.value as? String, "背景の写真あり")
        app.buttons["appearance.tryOn.previewKind.home"].tap()
        waitForPreviewLabel("ホームの見本", of: "appearance.tryOn.preview", in: app)

        // 長押ししている間は着せ替える前を出し、指を離すと試着に戻る（見本は押せず、中の予定は開かない）
        tryOn.press(forDuration: 1.5)
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value BEGINSWITH %@", "背景の写真あり"), object: tryOn)
        _ = XCTWaiter().wait(for: [restored], timeout: 5)
        XCTAssertEqual(tryOn.value as? String, "背景の写真あり、暗幕の濃さ 50%、ぼかしの強さ 40%、推しの写真の飾りなし")
        XCTAssertTrue(app.buttons["appearance.tryOn.close"].exists)

        // 閉じると、全画面で替えた見本のまま着せ替えの画面に戻る
        app.buttons["appearance.tryOn.close"].tap()
        XCTAssertTrue(app.navigationBars["着せ替え"].waitForExistence(timeout: 5))
        XCTAssertTrue(tryOn.waitForNonExistence(timeout: 5))
        waitForPreviewLabel("ホームの見本", in: app)

        // 全画面の「Plus で使う」は、全画面を閉じてから課金画面を開く。閉じると着せ替えの画面に戻る
        app.buttons["appearance.fullScreen"].tap()
        let openPaywall = app.buttons["appearance.tryOn.openPaywall"]
        XCTAssertTrue(openPaywall.waitForExistence(timeout: 5))
        openPaywall.tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 10))
        XCTAssertFalse(tryOn.exists)
        app.buttons["plusPaywall.close"].tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["着せ替え"].exists)
    }
}
