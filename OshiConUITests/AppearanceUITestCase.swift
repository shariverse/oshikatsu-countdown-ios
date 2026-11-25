//
//  AppearanceUITestCase.swift
//  OshiConUITests
//

import XCTest

/// 着せ替えの画面の UI テスト（`AppearanceUITests`・`AppearanceTryOnUITests`）で共通に使う、起動と操作。
///
/// - `PhotosPicker` は操作できないので、`-useTestPhoto` で生成した画像を選ぶ（メモリ上のストアのときだけ効く）
/// - メモリ上のストアでは着せ替えの設定と写真が起動のたびに空になるので、1 回の起動の中で写真を選んでから確かめる
/// - ホームと詳細の地は読み上げから外しているので、メモリ上のストアのときだけ置く口（`home.appearance`・`eventDetail.appearance`。
///   `AppearanceUITestMarker`）のラベルで、描いているもの（`standard`・`photo`・`decoration`）を確かめる
/// - 見本に映ったかは、見本（`appearance.preview`。全画面の試着は `appearance.tryOn.preview`）の読み上げの名前と値で確かめる
/// - 設定は見本の下のトレーにあり、「背景」「飾り」のタブ（`appearance.tab.background`・`appearance.tab.decoration`）で分かれている。
///   見本はトレーの外に置いているので、送るときはトレーの設定（`appearance.form`）の上で指を動かす
/// - 着せ替えの画面ではタブバーを隠すので、ほかのタブへは設定に戻ってから移る
class AppearanceUITestCase: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 導線を終えた状態で起動し、設定のタブを開く。
    @MainActor
    func launchSettings(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useInMemoryStore", "-useTestPhoto", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"] + arguments
        app.launchEnvironment = [
            "OSHICON_DEFAULT_hasCompletedOnboarding": "YES",
            "OSHICON_DEFAULT_showsPastEvents": "NO"
        ]
        app.launch()
        app.selectTab("設定")
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 2))
        return app
    }

    /// 設定の「着せ替え」の行から着せ替えの画面を開く。
    @MainActor
    func openAppearance(in app: XCUIApplication) {
        let row = app.buttons["settings.appearance"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["着せ替え"].waitForExistence(timeout: 5))
    }

    /// ホームの見本（読み上げの値に、映しているものが入る）。
    @MainActor
    func preview(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["appearance.preview"].firstMatch
    }

    /// 着せ替えの設定のトレーの中身（見本の外。スクロールする）。
    @MainActor
    func form(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["appearance.form"].firstMatch
    }

    /// 設定のトレーのタブ（`background`・`decoration`）を選ぶ。
    @MainActor
    func selectEditorTab(_ tab: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["appearance.tab.\(tab)"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), tab, file: file, line: line)
        // 押した後に選ばれたことを確かめ、選ばれていなければ押し直す（遅い Simulator では短いタッチが効かないことがある）
        for _ in 0..<3 where !button.isSelected {
            button.tap()
            _ = button.wait(for: \.isSelected, toEqual: true, timeout: 5)
        }
        XCTAssertTrue(button.isSelected, tab, file: file, line: line)
    }

    /// 着せ替えの画面から設定に戻り、タブバーの `title` のタブに移る（着せ替えの画面ではタブバーを隠している）。
    @MainActor
    func leaveAppearance(toTab title: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        app.navigationBars["着せ替え"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["settings.appearance"].waitForExistence(timeout: 5), file: file, line: line)
        app.selectTab(title, file: file, line: line)
    }

    /// 見本（`identifier`）の読み上げの名前が `label` になるまで待つ。
    @MainActor
    func waitForPreviewLabel(
        _ label: String,
        of identifier: String = "appearance.preview",
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), identifier, file: file, line: line)
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: element)
        _ = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(element.label, label, identifier, file: file, line: line)
    }

    /// 見本の読み上げの値が `texts` をすべて含むまで待つ。見本はトレーの外に置いているので、送らずに読める。
    /// 遅い Simulator では、値がそろっていても待ちが時間切れで返ることがあるので、待った後の値で確かめる。
    @MainActor
    func waitForPreview(in app: XCUIApplication, containing texts: [String], file: StaticString = #filePath, line: UInt = #line) {
        let element = preview(in: app)
        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
        let format = texts.map { _ in "value CONTAINS %@" }.joined(separator: " AND ")
        let predicate = NSPredicate(format: format, argumentArray: texts)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        _ = XCTWaiter().wait(for: [expectation], timeout: 5)
        let value = element.value as? String ?? "nil"
        XCTAssertTrue(texts.allSatisfy { value.contains($0) }, "見本の値: \(value)", file: file, line: line)
    }

    /// ホームか予定の詳細の地に描いているもの（`AppearanceUITestMarker`）が `expected` になるまで待つ。
    @MainActor
    func waitForMarker(
        _ identifier: String,
        in app: XCUIApplication,
        equalTo expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let marker = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(marker.waitForExistence(timeout: 5), identifier, file: file, line: line)
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: marker)
        _ = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(marker.label, expected, identifier, file: file, line: line)
    }

    /// 「背景」のタブの「写真を選ぶ／写真を変える」で生成した画像を選び、縦長の枠の調整画面で拡大してから「完了」する。
    @MainActor
    func pickAndCropPhoto(in app: XCUIApplication) {
        selectEditorTab("background", in: app)
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
        // 取り込むと「写真を変える」になり、そのとなりに「写真を外す」が出る
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "写真を変える"), object: select)
        _ = XCTWaiter().wait(for: [changed], timeout: 5)
        XCTAssertTrue(select.label.contains("写真を変える"), select.label)
        let remove = app.buttons["appearance.removePhoto"]
        reveal(remove, in: app)
        XCTAssertTrue(remove.waitForExistence(timeout: 2))
    }

    /// スイッチを押して、値を `expected` にする（ラベルの文字ではなく、右端のスイッチを押す）。
    @MainActor
    func toggle(_ identifier: String, in app: XCUIApplication, to expected: String) {
        let element = app.switches[identifier]
        reveal(element, in: app)
        XCTAssertTrue(element.exists, identifier)
        // 送った後の惰性が止まってから押す（動いている間に押すと、スクロールが止まるだけで切り替わらない）
        element.waitUntilStill()
        element.setSwitch(to: expected)
    }

    /// ホームのタブで今日の予定を足し、その詳細を開く。
    @MainActor
    func addEventAndOpenDetail(in app: XCUIApplication) {
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

    /// `element` が画面の中で押せるところに来るまで、トレーの設定をゆっくり送る。下へ送っても来なければ上へ送る。
    /// 何度か送っても来なければそのまま返す。押さない要素は `needsHittable` を false にし、あれば止める。
    ///
    /// トレーの下の端から少しだけのぞいている要素も `isHittable` になる（見えている部分のまん中で判定される）。
    /// 押すのは要素のまん中の高さなので、そこがトレーの見えている範囲に入るまで送る。
    @MainActor
    func reveal(_ element: XCUIElement, in app: XCUIApplication, needsHittable: Bool = true, maxSwipes: Int = 4) {
        let form = form(in: app)
        let isReady = {
            guard element.exists else { return false }
            guard needsHittable else { return true }
            // 上下の端のきわは押さない（下の端はホームインジケータに近い）
            let visible = form.frame.insetBy(dx: 0, dy: 12)
            let middle = element.frame.midY
            return element.isHittable && visible.minY <= middle && middle <= visible.maxY
        }
        for upward in [true, false] {
            var swipes = 0
            while !isReady(), swipes < maxSwipes {
                scroll(form, upward: upward)
                swipes += 1
            }
        }
    }

    /// 見本が画面の中にあり、`control`（いま動かしている設定）と重なっていないことを確かめる。
    @MainActor
    func assertPreviewVisible(
        besides control: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let preview = preview(in: app)
        XCTAssertTrue(preview.exists, file: file, line: line)
        let screen = app.windows.firstMatch.frame
        XCTAssertTrue(screen.contains(preview.frame), "見本: \(preview.frame)、画面: \(screen)", file: file, line: line)
        XCTAssertFalse(preview.frame.intersects(control.frame), "見本: \(preview.frame)、設定: \(control.frame)", file: file, line: line)
    }

    /// スライダー `slider` を端（`position` が 1 なら右、0 なら左）へ動かし、値が狙った向きに動いたことを確かめて、動いた後の値（「100%」など）を返す。
    /// 見本に映ったかは、返した値で確かめる（ちょうど端の値は求めない）。動かす前と値を読む前に、スライダーを画面の中に戻す。
    @MainActor
    func move(
        _ slider: XCUIElement,
        to position: CGFloat,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let initial = slider.value as? String ?? ""
        reveal(slider, in: app)
        drag(slider, to: position)
        reveal(slider, in: app)
        let moved = slider.value as? String ?? ""
        let (before, after) = (initial.percentValue, moved.percentValue)
        let message = "スライダーが狙った向きに動いていない: \(initial) → \(moved)"
        XCTAssertTrue(position > 0.5 ? after > before : after < before, message, file: file, line: line)
        return moved
    }

    /// スライダーのつまみを押さえ、端までゆっくり引いて、止めてから離す。1 回だけ引き、引き直さない。
    ///
    /// iOS 26 のスライダーは、つまみが指に遅れて付いてくる。`adjust(toNormalizedSliderPosition:)` は速く引いてすぐ指を離すので、
    /// 遅い CI の Simulator ではつまみが端に届く前に指が離れ、途中（75〜95%）で止まる。そこから短く速く引き直しても、つまみは付いてこない。
    /// 右へ引き直した指は、iOS 26 の「画面のどこからでも戻れるスワイプ」として効いて、着せ替えの画面から設定に戻ることがあった（#317）。
    @MainActor
    func drag(_ slider: XCUIElement, to position: CGFloat) {
        // 送った後の惰性が止まってから押さえる（動いている間に押すと、スクロールが止まるだけでつまみをつかめない）
        slider.waitUntilStill()
        // つまみのまん中が動く範囲は、スライダーの両端からつまみの幅の半分（iOS 26 では 19pt ほど）だけ内側にある
        let inset = 19 / max(slider.frame.width, 1)
        let thumbOffset = inset + slider.normalizedSliderPosition * (1 - 2 * inset)
        let thumb = slider.coordinate(withNormalizedOffset: CGVector(dx: thumbOffset, dy: 0.5))
        let end = slider.coordinate(withNormalizedOffset: CGVector(dx: position, dy: 0.5))
        thumb.press(forDuration: 0.3, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.5)
    }

    /// トレーの設定をゆっくり 1 回送る。スライダーの上から縦に送るとスライダーが指を取って送られないので、
    /// スライダーの無い左の端（行の外の余白）を縦に送る。見本はトレーの外にあり、見本の上では送れない。
    @MainActor
    func scroll(_ form: XCUIElement, upward: Bool) {
        let top = form.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.25))
        let bottom = form.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.75))
        let (start, end) = upward ? (bottom, top) : (top, bottom)
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)
    }
}

extension String {
    /// スライダーの値の文字（「40%」）を数にする。読めなければ -1。
    var percentValue: Int {
        Int(dropLast()) ?? -1
    }
}
