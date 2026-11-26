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
        // 閉じるボタンはナビゲーションバーの「閉じる」だけ。SubscriptionStoreView がシートの中で自動で出す ×（xmark）は隠している
        XCTAssertFalse(app.buttons["xmark"].waitForExistence(timeout: 3))

        app.buttons["plusPaywall.close"].tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.navigationBars["設定"].exists)
    }

    /// 利用規約・プライバシーポリシーは、アプリから出ずにアプリの中の Safari の画面で開き、「完了」で課金画面に戻る。
    /// ページの中身は確かめない（読み込みは Safari が受け持ち、通信の状態でテストが揺れないように）。
    @MainActor
    func testLegalLinksOpenInApp() throws {
        let app = launchSettings(arguments: ["-plusLocked"])

        let plusRow = app.buttons["settings.plus"]
        XCTAssertTrue(plusRow.waitForExistence(timeout: 5))
        plusRow.tap()
        let paywallBar = app.navigationBars["推し活カウントダウン Plus"]
        XCTAssertTrue(paywallBar.waitForExistence(timeout: 5))

        // 同じリンクを 2 回開けること（閉じたあとにシートの状態が残らないこと）も確かめる
        for identifier in ["plusPaywall.terms", "plusPaywall.privacyPolicy", "plusPaywall.terms"] {
            let link = app.descendants(matching: .any)[identifier].firstMatch
            XCTAssertTrue(link.waitForExistence(timeout: 2), identifier)
            link.tap()

            // Safari の画面（別のプロセスが描く）。文言はアプリではなく端末の言語で出る（CI の Simulator は英語）。
            // 閉じるボタンは iOS 26 で「閉じる」（Close）、それより前は「完了」（Done）
            let browser = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "BrowserView")).firstMatch
            XCTAssertTrue(browser.waitForExistence(timeout: 10), identifier)
            XCTAssertEqual(app.state, .runningForeground, identifier)
            let close = browser.buttons.matching(NSPredicate(format: "label IN %@", ["閉じる", "完了", "Close", "Done"])).firstMatch
            XCTAssertTrue(close.waitForExistence(timeout: 5), identifier)
            // Safari の画面の要素は、要素の tap() では押せないことがある（別のプロセスが描くため）。要素の中心を座標で押す
            close.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(browser.waitForNonExistence(timeout: 5), identifier)
            XCTAssertTrue(paywallBar.exists, identifier)
        }
    }

    /// Plus が使える状態では、行と課金画面にその旨を出す。
    /// 課金画面の見出し（その旨の印がある）は `SubscriptionStoreView` の中にあり、商品を読み込み終えるまで出ない。
    /// CI では商品の読み込みに時間がかかり、読み込めないこともあるので、読み込めないときは見出しの確認だけ飛ばす。
    @MainActor
    func testPlusRowWhenUnlocked() throws {
        let app = launchSettings(arguments: ["-plusUnlocked"])

        let plusRow = app.buttons["settings.plus"]
        XCTAssertTrue(plusRow.waitForExistence(timeout: 5))
        XCTAssertTrue(plusRow.label.contains("Plus をお使いいただけます"))
        plusRow.tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 5))

        guard app.buttons["Subscription Store View Button"].waitForExistence(timeout: 15) else {
            throw XCTSkip("サブスクリプションの商品を読み込めなかったので、課金画面の見出しを確かめられない")
        }
        XCTAssertTrue(app.descendants(matching: .any)["plusPaywall.unlocked"].firstMatch.waitForExistence(timeout: 2))
    }

    /// 課金画面の見出しは、商品を読み込んだあともアプリの言語（ここでは日本語）のまま。
    /// `SubscriptionStoreView` は中身の locale を商品の価格の locale（ストアフロントの言語）に置き換える。
    /// UI テストでは sandbox の米国のストアフロントになるので、入れ直さないと見出しが英語になる。
    /// 商品を読み込めないときは置き換えも起きず、確かめられないので飛ばす。
    @MainActor
    func testPaywallHeaderStaysInAppLanguageAfterProductsLoad() throws {
        let app = launchSettings(arguments: ["-plusLocked"])
        let plusRow = app.buttons["settings.plus"]
        XCTAssertTrue(plusRow.waitForExistence(timeout: 5))
        plusRow.tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 5))

        guard app.buttons["Subscription Store View Button"].waitForExistence(timeout: 15) else {
            throw XCTSkip("サブスクリプションの商品を読み込めなかったので、見出しの言語を確かめられない")
        }
        XCTAssertTrue(app.staticTexts["推しの写真で、ホーム画面とアプリをもっと自分らしく。"].waitForExistence(timeout: 2))
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

    /// 開発版では、推しの写真ウィジェットの課金画面のリンクで課金画面を開く。
    @MainActor
    func testPhotoWidgetLinkOpensPaywall() throws {
        let app = try launchAndOpenPaywallLink(arguments: [])

        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["plusPaywall.restore"].firstMatch.waitForExistence(timeout: 2))

        app.buttons["plusPaywall.close"].tap()
        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    /// App Store 版でも、推しの写真ウィジェットの課金画面のリンクで課金画面を開く。
    @MainActor
    func testPhotoWidgetLinkOpensPaywallInAppStoreDistribution() throws {
        let app = try launchAndOpenPaywallLink(arguments: ["-simulateAppStoreDistribution"])

        XCTAssertTrue(app.navigationBars["推し活カウントダウン Plus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["plusPaywall.restore"].firstMatch.waitForExistence(timeout: 2))
    }

    /// 課金画面を開いたまま、ウィジェット・通知のリンクで予定の詳細を開くと、課金画面を閉じてホームのタブに移る（開いた詳細が課金画面の下に隠れない）。
    /// 予定の id は無いものでよい（リンクの受け方は同じで、詳細はすぐホームの最初の画面に戻る）。
    @MainActor
    func testEventLinkClosesPaywall() throws {
        let app = launchSettings(arguments: ["-plusLocked"])
        let plusRow = app.buttons["settings.plus"]
        XCTAssertTrue(plusRow.waitForExistence(timeout: 5))
        plusRow.tap()
        let paywall = app.navigationBars["推し活カウントダウン Plus"]
        XCTAssertTrue(paywall.waitForExistence(timeout: 5))

        app.open(try XCTUnwrap(URL(string: "oshicon://event/\(UUID().uuidString)")))
        XCTAssertTrue(paywall.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home.addEvent"].waitForExistence(timeout: 5))
    }

    /// App Store 版でも、設定に Plus の行を出す。
    @MainActor
    func testPlusRowShownInAppStoreDistribution() throws {
        let app = launchSettings(arguments: ["-plusLocked", "-simulateAppStoreDistribution"])

        XCTAssertTrue(app.buttons["settings.plus"].waitForExistence(timeout: 5))
    }
}
