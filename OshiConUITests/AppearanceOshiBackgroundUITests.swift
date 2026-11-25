//
//  AppearanceOshiBackgroundUITests.swift
//  OshiConUITests
//

import XCTest

/// 推しごとの背景の写真（「背景」のタブの「共通」と推しの枠）が、着せ替えの画面の見本と、ホームの絞り込み・予定の詳細に効くかの導線。
/// 起動と操作は `AppearanceUITestCase`。見本の推し（`-seedSampleData`）は、並びの 1 番目が LUMINA、2 番目がミナト。
/// ピン留めのライブは LUMINA、ミナトの予定は誕生日だけ。
final class AppearanceOshiBackgroundUITests: AppearanceUITestCase {
    /// 見本の読み上げの値に `text` が無くなるまで待つ。遅い Simulator では待ちが時間切れで返ることがあるので、待った後の値で確かめる。
    @MainActor
    private func waitForPreview(in app: XCUIApplication, notContaining text: String, file: StaticString = #filePath, line: UInt = #line) {
        let element = preview(in: app)
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "NOT (value CONTAINS %@)", text), object: element)
        _ = XCTWaiter().wait(for: [expectation], timeout: 5)
        let value = element.value as? String ?? "nil"
        XCTAssertFalse(value.contains(text), "見本の値: \(value)", file: file, line: line)
    }

    /// 「背景」のタブの枠（`common` か推しの並びの番号）を選ぶ。選ばれたことを確かめ、選ばれていなければ押し直す。
    @MainActor
    @discardableResult
    private func selectBackgroundTarget(
        _ target: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let chip = app.buttons["appearance.backgroundTarget.\(target)"]
        reveal(chip, in: app)
        XCTAssertTrue(chip.exists, target, file: file, line: line)
        chip.waitUntilStill()
        for _ in 0..<3 where !chip.isSelected {
            chip.tap()
            _ = chip.wait(for: \.isSelected, toEqual: true, timeout: 5)
        }
        XCTAssertTrue(chip.isSelected, target, file: file, line: line)
        return chip
    }

    /// ホームの絞り込み（`title` の推し、または「すべて」）を押す。
    @MainActor
    private func filterHome(by title: String, in app: XCUIApplication) {
        let chip = app.buttons[title].firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 5), title)
        chip.tap()
    }

    /// 予定の詳細から前の画面（ホーム）に戻る。
    @MainActor
    private func leaveDetail(in app: XCUIApplication) {
        app.navigationBars.firstMatch.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["home.addEvent"].waitForExistence(timeout: 5))
    }

    /// 共通の写真と推しの写真を選ぶと、見本は選んでいる枠の推しで映し、ホームは絞り込んでいる推し、予定の詳細はその予定の推しの写真を敷く。
    @MainActor
    func testOshiBackgroundFollowsFilterAndEventDetail() throws {
        let app = launchSettings(arguments: ["-plusUnlocked", "-seedSampleData"])
        openAppearance(in: app)
        selectEditorTab("background", in: app)

        // 初めは共通の枠を選んでいる。共通の写真を選ぶと、すべてのホームの見本に映る
        let common = selectBackgroundTarget("common", in: app)
        XCTAssertEqual(common.label, "共通")
        XCTAssertEqual(common.value as? String, "背景の写真なし")
        pickAndCropPhoto(in: app)
        waitForPreview(in: app, containing: ["背景の写真あり"])
        waitForPreview(in: app, notContaining: "推しの背景の写真あり")
        XCTAssertEqual(common.value as? String, "背景の写真あり")

        // ミナトの枠を選ぶと、見本のホームはミナトで絞り込む。ミナトの写真はまだ無いので共通の写真のまま
        let minato = selectBackgroundTarget("1", in: app)
        XCTAssertEqual(minato.label, "ミナト")
        XCTAssertEqual(minato.value as? String, "背景の写真なし")
        XCTAssertFalse(common.isSelected)
        XCTAssertTrue(app.buttons["appearance.selectPhoto"].label.contains("写真を選ぶ"))
        waitForPreview(in: app, containing: ["背景の写真あり"])
        waitForPreview(in: app, notContaining: "推しの背景の写真あり")

        // ミナトの写真を選ぶと、ホームと予定の詳細の見本はミナトの写真になる
        pickAndCropPhoto(in: app)
        waitForPreview(in: app, containing: ["推しの背景の写真あり"])
        XCTAssertEqual(minato.value as? String, "背景の写真あり")
        app.buttons["appearance.previewKind.eventDetail"].tap()
        waitForPreviewLabel("予定の詳細の見本", in: app)
        waitForPreview(in: app, containing: ["推しの背景の写真あり"])
        app.buttons["appearance.previewKind.home"].tap()
        waitForPreviewLabel("ホームの見本", in: app)

        // 共通の枠に戻すと、見本は絞り込まないホームで、共通の写真
        selectBackgroundTarget("common", in: app)
        XCTAssertTrue(app.buttons["appearance.selectPhoto"].label.contains("写真を変える"))
        waitForPreview(in: app, notContaining: "推しの背景の写真あり")
        waitForPreview(in: app, containing: ["背景の写真あり"])

        // ホーム: すべては共通の写真、ミナトで絞り込むとミナトの写真、写真の無い LUMINA は共通の写真
        leaveAppearance(toTab: "ホーム", in: app)
        waitForMarker("home.appearance", in: app, equalTo: "photo")
        filterHome(by: "ミナト", in: app)
        waitForMarker("home.appearance", in: app, equalTo: "oshiPhoto")
        filterHome(by: "LUMINA", in: app)
        waitForMarker("home.appearance", in: app, equalTo: "photo")

        // 予定の詳細: ミナトの誕生日はミナトの写真、LUMINA のライブは共通の写真
        filterHome(by: "ミナト", in: app)
        waitForMarker("home.appearance", in: app, equalTo: "oshiPhoto")
        let featured = app.buttons["home.featuredEvent"].firstMatch
        XCTAssertTrue(featured.waitForExistence(timeout: 5))
        XCTAssertTrue(featured.label.contains("ミナト"), featured.label)
        featured.tap()
        waitForMarker("eventDetail.appearance", in: app, equalTo: "oshiPhoto")
        leaveDetail(in: app)

        filterHome(by: "すべて", in: app)
        waitForMarker("home.appearance", in: app, equalTo: "photo")
        XCTAssertTrue(featured.waitForExistence(timeout: 5))
        XCTAssertTrue(featured.label.contains("LUMINA"), featured.label)
        featured.tap()
        waitForMarker("eventDetail.appearance", in: app, equalTo: "photo")
    }
}
