//
//  PlusPaywallUITests.swift
//  OshiConUITests
//

import XCTest

/// 設定の Plus の行と、推しの写真ウィジェットのリンク → 課金画面の導線。
///
/// UI テストは DEBUG のビルドなので、設定に Plus の行が出る。App Store 版の画面は `-simulateAppStoreDistribution` で確かめる。
/// メモリ上のストアでは StoreKit に問い合わせないので、Plus の状態は起動引数（`-plusLocked`・`-plusUnlocked`）で固定する。
final class PlusPaywallUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 導線を終えた状態で起動し、設定のタブを開く。
    @MainActor
    private func launchSettings(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useInMemoryStore", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"] + arguments
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

    /// Plus の行から課金画面を開く。購入の復元・利用規約・プライバシーポリシーがあり、閉じると設定に戻る。
    @MainActor
    func testPlusRowOpensPaywall() throws {
        let app = launchSettings(arguments: ["-plusLocked"])

        let plusRow = app.buttons["settings.plus"]
        XCTAssertTrue(plusRow.waitForExistence(timeout: 5))
        XCTAssertTrue(plusRow.label.contains("推し活カウントダウン Plus"))
        plusRow.tap()

        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 5))
        for identifier in ["plusPaywall.restore", "plusPaywall.terms", "plusPaywall.privacyPolicy"] {
            XCTAssertTrue(app.descendants(matching: .any)[identifier].firstMatch.waitForExistence(timeout: 2), identifier)
        }
        XCTAssertFalse(app.descendants(matching: .any)["plusPaywall.unlocked"].exists)

        app.buttons["plusPaywall.close"].tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.navigationBars["設定"].exists)
    }

    /// Plus が使える状態では、行と課金画面にその旨を出す。
    @MainActor
    func testPlusRowWhenUnlocked() throws {
        let app = launchSettings(arguments: ["-plusUnlocked"])

        let plusRow = app.buttons["settings.plus"]
        XCTAssertTrue(plusRow.waitForExistence(timeout: 5))
        XCTAssertTrue(plusRow.label.contains("Plus をお使いいただけます"))
        plusRow.tap()
        XCTAssertTrue(app.descendants(matching: .any)["plusPaywall.unlocked"].firstMatch.waitForExistence(timeout: 5))
    }

    /// 導線を終えた状態で起動し、Plus でない人が推しの写真ウィジェットを押したときのリンク（`oshicon://plus/<予定の id>`）を開く。
    @MainActor
    private func launchAndOpenPaywallLink(arguments: [String]) throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useInMemoryStore", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP", "-plusLocked"] + arguments
        app.launchEnvironment = [
            "OSHICON_DEFAULT_hasCompletedOnboarding": "YES",
            "OSHICON_DEFAULT_showsPastEvents": "NO"
        ]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        app.open(try XCTUnwrap(URL(string: "oshicon://plus/\(UUID().uuidString)")))
        return app
    }

    /// 開発版（と TestFlight）では、推しの写真ウィジェットの課金画面のリンクで課金画面を開く。
    @MainActor
    func testPhotoWidgetLinkOpensPaywall() throws {
        let app = try launchAndOpenPaywallLink(arguments: [])

        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["plusPaywall.restore"].firstMatch.waitForExistence(timeout: 2))

        app.buttons["plusPaywall.close"].tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    /// App Store 版では、推しの写真ウィジェットの課金画面のリンクで課金画面を開かない。
    @MainActor
    func testPhotoWidgetLinkDoesNotOpenPaywallInAppStoreDistribution() throws {
        let app = try launchAndOpenPaywallLink(arguments: ["-simulateAppStoreDistribution"])

        XCTAssertFalse(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    /// App Store 版では、設定に Plus の行を出さない。
    @MainActor
    func testPlusRowHiddenInAppStoreDistribution() throws {
        let app = launchSettings(arguments: ["-plusLocked", "-simulateAppStoreDistribution"])

        let showsPast = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "終わった予定も表示する")).firstMatch
        XCTAssertTrue(showsPast.waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["settings.plus"].waitForExistence(timeout: 2))
    }
}
