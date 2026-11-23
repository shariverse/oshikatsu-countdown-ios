//
//  AppearanceUITests.swift
//  OshiConUITests
//

import XCTest

/// 設定の「着せ替え」の行 → 着せ替えの画面（写真を選ぶ → 縦長の調整 → 見本に映る → ON/OFF と暗幕・ぼかし・飾りの濃さと量と出す推し → 課金画面）と、
/// ホームと予定の詳細に着せ替えが効くかの導線。
///
/// - `PhotosPicker` は操作できないので、`-useTestPhoto` で生成した画像を選ぶ（メモリ上のストアのときだけ効く）
/// - メモリ上のストアでは着せ替えの設定と写真が起動のたびに空になるので、1 回の起動の中で写真を選んでから確かめる
/// - ホームと詳細の地は読み上げから外しているので、メモリ上のストアのときだけ置く口（`home.appearance`・`eventDetail.appearance`。
///   `AppearanceUITestMarker`）のラベルで、描いているもの（`standard`・`photo`・`decoration`）を確かめる
/// - 見本に映ったかは、見本（`appearance.preview`）の読み上げの値で確かめる
final class AppearanceUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 導線を終えた状態で起動し、設定のタブを開く。
    @MainActor
    private func launchSettings(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useInMemoryStore", "-useTestPhoto", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"] + arguments
        app.launchEnvironment = [
            "OSHICON_DEFAULT_hasCompletedOnboarding": "YES",
            "OSHICON_DEFAULT_showsPastEvents": "NO"
        ]
        app.launch()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["設定"].tap()
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 2))
        return app
    }

    /// 設定の「着せ替え」の行から着せ替えの画面を開く。
    @MainActor
    private func openAppearance(in app: XCUIApplication) {
        let row = app.buttons["settings.appearance"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["着せ替え"].waitForExistence(timeout: 5))
    }

    /// ホームの見本（読み上げの値に、映しているものが入る）。
    @MainActor
    private func preview(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["appearance.preview"].firstMatch
    }

    /// 見本の読み上げの値が `texts` をすべて含むまで待つ。
    @MainActor
    private func waitForPreview(in app: XCUIApplication, containing texts: [String], file: StaticString = #filePath, line: UInt = #line) {
        let element = preview(in: app)
        reveal(element, in: app, needsHittable: false)
        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
        let format = texts.map { _ in "value CONTAINS %@" }.joined(separator: " AND ")
        let predicate = NSPredicate(format: format, argumentArray: texts)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "見本の値: \(element.value as? String ?? "nil")", file: file, line: line)
    }

    /// ホームか予定の詳細の地に描いているもの（`AppearanceUITestMarker`）が `expected` になるまで待つ。
    @MainActor
    private func waitForMarker(
        _ identifier: String,
        in app: XCUIApplication,
        equalTo expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let marker = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(marker.waitForExistence(timeout: 5), identifier, file: file, line: line)
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: marker)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "\(identifier): \(marker.label)", file: file, line: line)
    }

    /// 「写真を選ぶ／写真を変える」で生成した画像を選び、縦長の枠の調整画面で拡大してから「完了」する。
    @MainActor
    private func pickAndCropPhoto(in app: XCUIApplication) {
        let select = app.buttons["appearance.selectPhoto"]
        reveal(select, in: app)
        XCTAssertTrue(select.waitForExistence(timeout: 2))
        select.tap()

        XCTAssertTrue(app.staticTexts["移動と拡大・縮小"].waitForExistence(timeout: 5))
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
        app.buttons["photoCrop.done"].tap()
        XCTAssertTrue(app.navigationBars["着せ替え"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["appearance.removePhoto"].waitForExistence(timeout: 5))
    }

    /// スイッチを押す（ラベルの文字ではなく、右端のスイッチを押す）。
    @MainActor
    private func toggle(_ identifier: String, in app: XCUIApplication, to expected: String) {
        let element = app.switches[identifier]
        reveal(element, in: app)
        XCTAssertTrue(element.exists, identifier)
        // 送った後の惰性が止まってから押す（動いている間に押すと、スクロールが止まるだけで切り替わらない）
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expected), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [changed], timeout: 2), .completed, identifier)
        XCTAssertEqual(element.value as? String, expected, identifier)
    }

    /// ホームのタブで今日の予定を足し、その詳細を開く。
    @MainActor
    private func addEventAndOpenDetail(in app: XCUIApplication) {
        let add = app.buttons["home.addEvent"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        let title = app.textFields["タイトル"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        title.tap()
        title.typeText("5th LIVE")
        app.navigationBars["予定を追加"].buttons["保存"].tap()

        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "5th LIVE、")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        XCTAssertTrue(app.buttons["eventDetail.share"].waitForExistence(timeout: 2))
    }

    /// `element` が画面の中で押せるところに来るまで、ゆっくり送る。Form の画面の外の行は作られないので、下の行へ送っても来なければ上の行へ送る。
    /// 何度か送っても来なければそのまま返す。押さない要素（見本）は `needsHittable` を false にし、作られたら止める。
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, needsHittable: Bool = true, maxSwipes: Int = 4) {
        let isReady = { element.exists && (!needsHittable || element.isHittable) }
        for upward in [true, false] {
            var swipes = 0
            while !isReady(), swipes < maxSwipes {
                scroll(app, upward: upward)
                swipes += 1
            }
        }
    }

    /// 画面をゆっくり 1 回送る。スライダーの上から縦に送るとスライダーが指を取って送られないので、
    /// スライダーの無い左の端（行の外の余白）を縦に送る。
    @MainActor
    private func scroll(_ app: XCUIApplication, upward: Bool) {
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 0.3))
        let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 0.7))
        let (start, end) = upward ? (bottom, top) : (top, bottom)
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)
    }

    /// 背景の写真を選んだ後に、暗幕とぼかしのスライダーを別々に動かすと見本に映る（暗幕 100%・ぼかし 0% にして返す）。
    /// 背景を OFF にすると、スライダーは値を見せたまま押せなくなり、ON に戻すと押せる。
    @MainActor
    private func adjustScrimAndBlur(in app: XCUIApplication) {
        let scrim = app.sliders["appearance.backgroundScrim"]
        let blur = app.sliders["appearance.backgroundBlur"]
        reveal(blur, in: app)
        XCTAssertTrue(scrim.exists)
        XCTAssertTrue(scrim.isEnabled)
        XCTAssertEqual(scrim.value as? String, "50%")
        XCTAssertEqual(blur.value as? String, "40%")
        scrim.adjust(toNormalizedSliderPosition: 1)
        XCTAssertEqual(scrim.value as? String, "100%")
        XCTAssertEqual(blur.value as? String, "40%")
        blur.adjust(toNormalizedSliderPosition: 0)
        XCTAssertEqual(blur.value as? String, "0%")
        waitForPreview(in: app, containing: ["背景の写真あり", "暗幕の濃さ 100%", "ぼかしの強さ 0%"])

        toggle("appearance.backgroundToggle", in: app, to: "0")
        waitForPreview(in: app, containing: ["背景の写真なし"])
        reveal(blur, in: app, needsHittable: false)
        XCTAssertFalse(scrim.isEnabled)
        XCTAssertFalse(blur.isEnabled)
        XCTAssertEqual(scrim.value as? String, "100%")
        XCTAssertEqual(blur.value as? String, "0%")
        toggle("appearance.backgroundToggle", in: app, to: "1")
        XCTAssertTrue(scrim.isEnabled)
        XCTAssertTrue(blur.isEnabled)
        waitForPreview(in: app, containing: ["背景の写真あり"])
    }

    /// Plus でない人: 写真を選ぶ・変える・外す、ON/OFF、暗幕とぼかしのスライダーが見本に映り、課金画面を開ける。ホームと詳細は標準のまま。
    @MainActor
    func testTryOnWithoutPlusUpdatesPreviewAndOpensPaywall() throws {
        let app = launchSettings(arguments: ["-plusLocked"])
        openAppearance(in: app)
        XCTAssertTrue(app.buttons["appearance.openPaywall"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.descendants(matching: .any)["appearance.plusActive"].exists)
        waitForPreview(in: app, containing: ["背景の写真なし", "推しの写真の飾りなし"])

        // 写真を選んで縦長の枠で調整すると、Plus でなくても見本に映る（背景は ON、暗幕とぼかしは既定）
        pickAndCropPhoto(in: app)
        XCTAssertTrue(app.buttons["appearance.selectPhoto"].label.contains("写真を変える"))
        waitForPreview(in: app, containing: ["背景の写真あり", "暗幕の濃さ 50%", "ぼかしの強さ 40%"])

        adjustScrimAndBlur(in: app)
        toggle("appearance.decorationToggle", in: app, to: "1")
        waitForPreview(in: app, containing: ["背景の写真あり", "暗幕の濃さ 100%", "ぼかしの強さ 0%", "推しの写真の飾りあり"])

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

        // 案内から課金画面を開き、閉じると着せ替えの画面に戻る
        let openPaywall = app.buttons["appearance.openPaywall"]
        // いちばん上の行なので、上へ送ってから探す
        app.swipeDown(velocity: .fast)
        app.swipeDown(velocity: .fast)
        reveal(openPaywall, in: app)
        openPaywall.tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 5))
        app.buttons["plusPaywall.close"].tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.navigationBars["着せ替え"].exists)

        // Plus でなければ、ホームと詳細は標準の見た目のまま
        app.tabBars.firstMatch.buttons["ホーム"].tap()
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
        toggle("appearance.decorationToggle", in: app, to: "1")
        waitForPreview(in: app, containing: ["推しの写真の飾りあり"])

        // ホームと詳細に、写真と飾りが効く
        app.tabBars.firstMatch.buttons["ホーム"].tap()
        waitForMarker("home.appearance", in: app, equalTo: "photo,decoration")
        addEventAndOpenDetail(in: app)
        waitForMarker("eventDetail.appearance", in: app, equalTo: "photo,decoration")

        // 背景を OFF にすると、写真は消えて飾りだけになる。詳細ではタブバーが隠れるので、ホームに戻ってから設定のタブに移る
        app.navigationBars.firstMatch.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["home.addEvent"].waitForExistence(timeout: 5))
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["設定"].tap()
        XCTAssertTrue(app.navigationBars["着せ替え"].waitForExistence(timeout: 5))
        toggle("appearance.backgroundToggle", in: app, to: "0")
        tabBar.buttons["ホーム"].tap()
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

        // 飾りが OFF のときは、スライダーと推しのスイッチを押せない
        let opacity = app.sliders["appearance.decorationOpacity"]
        reveal(opacity, in: app)
        XCTAssertTrue(opacity.exists)
        XCTAssertFalse(opacity.isEnabled)
        XCTAssertEqual(opacity.value as? String, "40%")

        toggle("appearance.decorationToggle", in: app, to: "1")
        XCTAssertTrue(opacity.isEnabled)
        waitForPreview(in: app, containing: ["推しの写真の飾りあり", "飾りの濃さ 40%", "飾りの量 25%"])

        // いちばん濃く、いちばん多く（埋め尽くす）する。見本を見るために上へ送ったので、スライダーまで戻る
        reveal(opacity, in: app)
        opacity.adjust(toNormalizedSliderPosition: 1)
        XCTAssertEqual(opacity.value as? String, "100%")
        let amount = app.sliders["appearance.decorationAmount"]
        reveal(amount, in: app)
        amount.adjust(toNormalizedSliderPosition: 1)
        XCTAssertEqual(amount.value as? String, "100%")
        waitForPreview(in: app, containing: ["飾りの濃さ 100%", "飾りの量 100%"])

        // 見本の推し（写真なし）が並び、推しごとに外せる
        let firstOshi = app.switches["appearance.decorationOshi.0"]
        reveal(firstOshi, in: app)
        XCTAssertTrue(firstOshi.exists)
        XCTAssertEqual(firstOshi.value as? String, "1")
        XCTAssertTrue(app.staticTexts["写真がありません"].firstMatch.exists)
        toggle("appearance.decorationOshi.0", in: app, to: "0")
        toggle("appearance.decorationOshi.0", in: app, to: "1")

        // ホームにも飾りが効く
        app.tabBars.firstMatch.buttons["ホーム"].tap()
        waitForMarker("home.appearance", in: app, equalTo: "decoration")
    }

    /// App Store 版では、設定に「着せ替え」の行を出さない。
    @MainActor
    func testAppearanceRowHiddenInAppStoreDistribution() throws {
        let app = launchSettings(arguments: ["-plusUnlocked", "-simulateAppStoreDistribution"])

        let showsPast = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "終わった予定も表示する")).firstMatch
        XCTAssertTrue(showsPast.waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["settings.appearance"].waitForExistence(timeout: 2))
        // Plus が使えても、ホームは標準の見た目のまま（設定していないため）
        app.tabBars.firstMatch.buttons["ホーム"].tap()
        waitForMarker("home.appearance", in: app, equalTo: "standard")
    }
}
