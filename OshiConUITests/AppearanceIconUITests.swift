//
//  AppearanceIconUITests.swift
//  OshiConUITests
//

import XCTest

/// 着せ替えの画面の「アイコン」のタブ（アプリアイコンの色）の導線。起動と操作は `AppearanceUITestCase`。
///
/// メモリ上のストアではシステムの API（`setAlternateIconName`）を呼ばないので、ホーム画面に出ているアイコンの色は
/// 「アイコン」のタブに置く口（`appearance.icon.homeScreen`。`OshiColor` の生の値）で確かめる。
final class AppearanceIconUITests: AppearanceUITestCase {
    /// 「アイコン」のタブのアイコンの見本（読み上げの値は、選んでいる色の名前）。
    @MainActor
    private func iconPreview(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["appearance.icon.preview"].firstMatch
    }

    /// `color`（`OshiColor` の生の値）のアイコンを押し、選ばれたことを確かめる。
    @MainActor
    private func selectIcon(_ color: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["appearance.icon.\(color)"]
        reveal(button, in: app)
        XCTAssertTrue(button.exists, color, file: file, line: line)
        // 押した後に選ばれたことを確かめ、選ばれていなければ押し直す（遅い Simulator では短いタッチが効かないことがある）
        for _ in 0..<3 where !button.isSelected {
            button.tap()
            _ = button.wait(for: \.isSelected, toEqual: true, timeout: 5)
        }
        XCTAssertTrue(button.isSelected, color, file: file, line: line)
    }

    /// Plus でない人: 「アイコン」のタブでは上の見本がアイコンの見本になり、色を選ぶと見本に映るが、ホーム画面のアイコンは変えない。
    /// ほかのタブに戻ると、ホーム・予定の詳細・シェアの見本に戻る。
    @MainActor
    func testIconTabPreviewsColorWithoutPlus() throws {
        let app = launchSettings(arguments: ["-plusLocked"])
        openAppearance(in: app)
        waitForPreviewLabel("ホームの見本", in: app)

        selectEditorTab("icon", in: app)
        waitForPreviewLabel("アイコンの見本", of: "appearance.icon.preview", in: app)
        XCTAssertEqual(iconPreview(in: app).value as? String, "ピンク")
        XCTAssertFalse(preview(in: app).exists, "アイコンのタブでは、ホーム・予定の詳細・シェアの見本を出さない")
        XCTAssertTrue(app.buttons["appearance.icon.pink"].isSelected)
        XCTAssertTrue(app.buttons["appearance.openPaywall"].exists)

        selectIcon("mint", in: app)
        XCTAssertFalse(app.buttons["appearance.icon.pink"].isSelected)
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "ミント"), object: iconPreview(in: app))
        _ = XCTWaiter().wait(for: [changed], timeout: 5)
        XCTAssertEqual(iconPreview(in: app).value as? String, "ミント")
        // Plus でなければ、ホーム画面のアイコンは標準（ピンク）のまま
        waitForMarker("appearance.icon.homeScreen", in: app, equalTo: "pink")

        // ほかのタブに戻ると、ホーム・予定の詳細・シェアの見本に戻る。選んだ色は残る
        selectEditorTab("background", in: app)
        waitForPreviewLabel("ホームの見本", in: app)
        XCTAssertFalse(iconPreview(in: app).exists)
        selectEditorTab("icon", in: app)
        waitForPreviewLabel("アイコンの見本", of: "appearance.icon.preview", in: app)
        XCTAssertEqual(iconPreview(in: app).value as? String, "ミント")
        XCTAssertTrue(app.buttons["appearance.icon.mint"].isSelected)
    }

    /// Plus の人: 色を選ぶとホーム画面のアイコンも替わり、ピンクを選ぶと今のアイコン（主アイコン）に戻る。
    @MainActor
    func testIconTabChangesHomeScreenIconWithPlus() throws {
        let app = launchSettings(arguments: ["-plusUnlocked"])
        openAppearance(in: app)
        selectEditorTab("icon", in: app)
        waitForPreviewLabel("アイコンの見本", of: "appearance.icon.preview", in: app)
        waitForMarker("appearance.icon.homeScreen", in: app, equalTo: "pink")

        selectIcon("navy", in: app)
        waitForMarker("appearance.icon.homeScreen", in: app, equalTo: "navy")
        XCTAssertEqual(iconPreview(in: app).value as? String, "ネイビー")

        // 2 段目の色も選べる
        selectIcon("black", in: app)
        waitForMarker("appearance.icon.homeScreen", in: app, equalTo: "black")

        selectIcon("pink", in: app)
        waitForMarker("appearance.icon.homeScreen", in: app, equalTo: "pink")
    }
}
