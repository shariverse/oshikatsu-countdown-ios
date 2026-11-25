//
//  AppearanceUITests.swift
//  OshiConUITests
//

import XCTest

/// 設定の「着せ替え」の行 → 着せ替えの画面（写真を選ぶ → 縦長の調整 → 見本に映る → ON/OFF と暗幕・ぼかし・飾りの濃さと量と出す推し → 課金画面）と、
/// ホームと予定の詳細に着せ替えが効くかの導線。起動と操作は `AppearanceUITestCase`。
/// 見本の切り替えと全画面の試着は `AppearanceTryOnUITests`。
final class AppearanceUITests: AppearanceUITestCase {
    /// 背景の写真を選んだ後に、暗幕とぼかしのスライダーを別々に動かすと見本に映る（暗幕を濃く、ぼかしを弱くして、動いた後の値を返す）。
    /// 背景を OFF にすると、スライダーは値を見せたまま押せなくなり、ON に戻すと押せる。
    @MainActor
    private func adjustScrimAndBlur(in app: XCUIApplication) -> (scrim: String, blur: String) {
        selectEditorTab("background", in: app)
        let scrim = app.sliders["appearance.backgroundScrim"]
        let blur = app.sliders["appearance.backgroundBlur"]
        reveal(blur, in: app)
        XCTAssertTrue(scrim.exists)
        XCTAssertTrue(scrim.isEnabled)
        XCTAssertEqual(scrim.value as? String, "50%")
        XCTAssertEqual(blur.value as? String, "40%")
        assertPreviewVisible(besides: scrim, in: app)
        let scrimValue = move(scrim, to: 1, in: app)
        XCTAssertEqual(blur.value as? String, "40%")
        assertPreviewVisible(besides: blur, in: app)
        let blurValue = move(blur, to: 0, in: app)
        XCTAssertEqual(scrim.value as? String, scrimValue)
        waitForPreview(in: app, containing: ["背景の写真あり", "暗幕の濃さ \(scrimValue)", "ぼかしの強さ \(blurValue)"])

        toggle("appearance.backgroundToggle", in: app, to: "0")
        waitForPreview(in: app, containing: ["背景の写真なし"])
        reveal(blur, in: app, needsHittable: false)
        XCTAssertFalse(scrim.isEnabled)
        XCTAssertFalse(blur.isEnabled)
        XCTAssertEqual(scrim.value as? String, scrimValue)
        XCTAssertEqual(blur.value as? String, blurValue)
        toggle("appearance.backgroundToggle", in: app, to: "1")
        XCTAssertTrue(scrim.isEnabled)
        XCTAssertTrue(blur.isEnabled)
        waitForPreview(in: app, containing: ["背景の写真あり"])
        return (scrimValue, blurValue)
    }

    /// Plus でない人: 写真を選ぶ・変える・外す、ON/OFF、暗幕とぼかしのスライダーが見本に映り、課金画面を開ける。ホームと詳細は標準のまま。
    @MainActor
    func testTryOnWithoutPlusUpdatesPreviewAndOpensPaywall() throws {
        let app = launchSettings(arguments: ["-plusLocked"])
        openAppearance(in: app)
        XCTAssertTrue(app.buttons["appearance.openPaywall"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.descendants(matching: .any)["appearance.plusActive"].exists)
        waitForPreviewLabel("ホームの見本", in: app)
        waitForPreview(in: app, containing: ["背景の写真なし", "推しの写真の飾りなし"])

        // 写真を選んで縦長の枠で調整すると、Plus でなくても見本に映る（背景は ON、暗幕とぼかしは既定）
        pickAndCropPhoto(in: app)
        XCTAssertTrue(app.buttons["appearance.selectPhoto"].label.contains("写真を変える"))
        waitForPreview(in: app, containing: ["背景の写真あり", "暗幕の濃さ 50%", "ぼかしの強さ 40%"])

        let (scrimValue, blurValue) = adjustScrimAndBlur(in: app)
        selectEditorTab("decoration", in: app)
        toggle("appearance.decorationToggle", in: app, to: "1")
        waitForPreview(in: app, containing: ["背景の写真あり", "暗幕の濃さ \(scrimValue)", "ぼかしの強さ \(blurValue)", "推しの写真の飾りあり"])

        // 写真を変えても、外しても見本に映る
        pickAndCropPhoto(in: app)
        waitForPreview(in: app, containing: ["背景の写真あり"])
        let remove = app.buttons["appearance.removePhoto"]
        reveal(remove, in: app)
        remove.tap()
        XCTAssertTrue(remove.waitForNonExistence(timeout: 2))
        XCTAssertTrue(app.buttons["appearance.selectPhoto"].label.contains("写真を選ぶ"))
        waitForPreview(in: app, containing: ["背景の写真なし", "推しの写真の飾りあり"])

        // もう一度選んでおき、Plus でない人のホームと詳細が標準のままかを後で確かめる
        pickAndCropPhoto(in: app)
        waitForPreview(in: app, containing: ["背景の写真あり", "推しの写真の飾りあり"])

        // バーの「Plus で使う」から課金画面を開き、閉じると着せ替えの画面に戻る
        app.buttons["appearance.openPaywall"].tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 5))
        app.buttons["plusPaywall.close"].tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.navigationBars["着せ替え"].exists)

        // Plus でなければ、ホームと詳細は標準の見た目のまま
        leaveAppearance(toTab: "ホーム", in: app)
        waitForMarker("home.appearance", in: app, equalTo: "standard")
        addEventAndOpenDetail(in: app)
        waitForMarker("eventDetail.appearance", in: app, equalTo: "standard")
    }

    /// Plus の人: 着せ替えの画面で使えていることを示し、選んだ写真と飾りがホームと詳細に効く。
    @MainActor
    func testPlusAppliesAppearanceToHomeAndDetail() throws {
        let app = launchSettings(arguments: ["-plusUnlocked"])
        openAppearance(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["appearance.plusActive"].firstMatch.waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["appearance.openPaywall"].exists)

        pickAndCropPhoto(in: app)
        waitForPreview(in: app, containing: ["背景の写真あり", "暗幕の濃さ 50%", "ぼかしの強さ 40%"])
        selectEditorTab("decoration", in: app)
        toggle("appearance.decorationToggle", in: app, to: "1")
        waitForPreview(in: app, containing: ["推しの写真の飾りあり"])

        // Plus の人の全画面の試着には「Plus で使う」を出さない
        app.buttons["appearance.fullScreen"].tap()
        waitForPreviewLabel("ホームの見本", of: "appearance.tryOn.preview", in: app)
        XCTAssertFalse(app.buttons["appearance.tryOn.openPaywall"].exists)
        app.buttons["appearance.tryOn.close"].tap()
        XCTAssertTrue(app.navigationBars["着せ替え"].waitForExistence(timeout: 5))

        // ホームと詳細に、写真と飾りが効く
        leaveAppearance(toTab: "ホーム", in: app)
        waitForMarker("home.appearance", in: app, equalTo: "photo,decoration")
        addEventAndOpenDetail(in: app)
        waitForMarker("eventDetail.appearance", in: app, equalTo: "photo,decoration")

        // 背景を OFF にすると、写真は消えて飾りだけになる。詳細ではタブバーが隠れるので、ホームに戻ってから設定のタブに移る
        app.navigationBars.firstMatch.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["home.addEvent"].waitForExistence(timeout: 5))
        app.selectTab("設定")
        openAppearance(in: app)
        selectEditorTab("background", in: app)
        toggle("appearance.backgroundToggle", in: app, to: "0")
        leaveAppearance(toTab: "ホーム", in: app)
        waitForMarker("home.appearance", in: app, equalTo: "decoration")
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "5th LIVE、")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        waitForMarker("eventDetail.appearance", in: app, equalTo: "decoration")
    }

    /// 飾りの濃さと量のスライダー・飾りに出す推しのスイッチが見本に映り、ホームにも効く。飾りが OFF のときは押せない。
    @MainActor
    func testDecorationOpacityAmountAndOshis() throws {
        let app = launchSettings(arguments: ["-plusUnlocked", "-seedSampleData"])
        openAppearance(in: app)
        selectEditorTab("decoration", in: app)

        // 飾りが OFF のときは、スライダーと推しのスイッチを押せない
        let opacity = app.sliders["appearance.decorationOpacity"]
        reveal(opacity, in: app, needsHittable: false)
        XCTAssertTrue(opacity.exists)
        XCTAssertFalse(opacity.isEnabled)
        XCTAssertEqual(opacity.value as? String, "40%")

        toggle("appearance.decorationToggle", in: app, to: "1")
        XCTAssertTrue(opacity.isEnabled)
        waitForPreview(in: app, containing: ["推しの写真の飾りあり", "飾りの濃さ 40%", "飾りの量 25%"])

        // 濃く、多くする（埋め尽くす側へ）。スライダーを動かしている間も、見本は画面の中にあり、その場で映る
        reveal(opacity, in: app)
        assertPreviewVisible(besides: opacity, in: app)
        let opacityValue = move(opacity, to: 1, in: app)
        waitForPreview(in: app, containing: ["飾りの濃さ \(opacityValue)", "飾りの量 25%"])
        let amount = app.sliders["appearance.decorationAmount"]
        reveal(amount, in: app)
        assertPreviewVisible(besides: amount, in: app)
        let amountValue = move(amount, to: 1, in: app)
        waitForPreview(in: app, containing: ["飾りの濃さ \(opacityValue)", "飾りの量 \(amountValue)"])

        // 見本の推し（写真なし）が並び、推しごとに外せる
        let firstOshi = app.switches["appearance.decorationOshi.0"]
        reveal(firstOshi, in: app)
        XCTAssertTrue(firstOshi.exists)
        XCTAssertEqual(firstOshi.value as? String, "1")
        XCTAssertTrue(firstOshi.label.contains("写真がありません"), firstOshi.label)
        assertPreviewVisible(besides: firstOshi, in: app)
        toggle("appearance.decorationOshi.0", in: app, to: "0")
        toggle("appearance.decorationOshi.0", in: app, to: "1")

        // ホームにも飾りが効く
        leaveAppearance(toTab: "ホーム", in: app)
        waitForMarker("home.appearance", in: app, equalTo: "decoration")
    }

    /// App Store 版でも、設定に「着せ替え」の行を出す。
    @MainActor
    func testAppearanceRowShownInAppStoreDistribution() throws {
        let app = launchSettings(arguments: ["-plusUnlocked", "-simulateAppStoreDistribution"])

        XCTAssertTrue(app.buttons["settings.appearance"].waitForExistence(timeout: 5))
        // Plus が使えても、ホームは標準の見た目のまま（設定していないため）
        app.selectTab("ホーム")
        waitForMarker("home.appearance", in: app, equalTo: "standard")
    }
}
