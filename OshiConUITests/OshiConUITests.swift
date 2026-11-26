//
//  OshiConUITests.swift
//  OshiConUITests
//
//  Created by 村石 拓海 on 2024/05/12.
//

import XCTest

final class OshiConUITests: XCTestCase {
    override func setUpWithError() throws {
        // UI テストでは失敗した時点で即座に止める
        continueAfterFailure = false
    }

    /// 端末に残ったデータに左右されないよう、メモリ上のストアで起動し、設定（UserDefaults）の初期値も決める。
    /// 起動引数で渡すとアプリの中で書き換えられなくなる（導線を終えてもタブに切り替わらない）ので、環境変数で渡す。
    /// メモリ上のストアでは StoreKit に問い合わせず、Plus は使えない状態になる。使える状態にするときは `arguments` に `-plusUnlocked` を渡す。
    @MainActor
    private func launch(hasCompletedOnboarding: Bool, arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        // 文言で要素を探すので、Simulator の言語にかかわらず日本語で起動する
        app.launchArguments = ["-useInMemoryStore", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"] + arguments
        app.launchEnvironment = [
            "OSHICON_DEFAULT_hasCompletedOnboarding": hasCompletedOnboarding ? "YES" : "NO",
            "OSHICON_DEFAULT_showsPastEvents": "NO",
            // 前のテストで切り替えた値を残さない（メモリ上のストアでは予約も許可も求めない）
            "OSHICON_DEFAULT_remindersEnabled": "YES"
        ]
        app.launch()
        return app
    }

    @MainActor
    func testFirstLaunchShowsOnboarding() throws {
        let app = launch(hasCompletedOnboarding: false)
        XCTAssertTrue(app.navigationBars["ステップ 1 / 2"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }

    @MainActor
    func testOnboardingRegistersOshiAndFirstEvent() throws {
        let app = launch(hasCompletedOnboarding: false)
        XCTAssertTrue(app.navigationBars["ステップ 1 / 2"].waitForExistence(timeout: 5))
        let next = app.buttons["次へ：最初の予定を登録"]
        XCTAssertFalse(next.isEnabled)
        let name = app.textFields["推しの名前"]
        name.tap()
        name.typeText("ミナト")
        next.tap()

        // 2 歩目では、登録したばかりの推しを選んでおく
        XCTAssertTrue(app.navigationBars["ステップ 2 / 2"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch.exists)
        let start = app.buttons["保存してはじめる"]
        XCTAssertFalse(start.isEnabled)
        let title = app.textFields["タイトル"]
        title.tap()
        title.typeText("5th LIVE")
        start.tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 2))
    }

    @MainActor
    func testOnboardingCanBeSkipped() throws {
        let app = launch(hasCompletedOnboarding: false)
        XCTAssertTrue(app.navigationBars["ステップ 1 / 2"].waitForExistence(timeout: 5))
        app.navigationBars["ステップ 1 / 2"].buttons["あとで"].tap()
        XCTAssertTrue(app.navigationBars["ステップ 2 / 2"].waitForExistence(timeout: 2))
        app.navigationBars["ステップ 2 / 2"].buttons["あとで"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 2))
    }

    @MainActor
    func testTabsSwitchBetweenHomeOshiAndSettings() throws {
        let app = launch(hasCompletedOnboarding: true)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        assertShowsHome(app)

        app.selectTab("推し")
        XCTAssertTrue(app.navigationBars["推し"].waitForExistence(timeout: 2))

        app.selectTab("設定")
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 2))

        app.selectTab("ホーム")
        assertShowsHome(app)
    }

    /// ホームが出ていることを確かめる。バーにタイトルの文字は出さず（右上の ＋ だけ）、画面の名前はバーに残す。
    @MainActor
    private func assertShowsHome(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.buttons["home.addEvent"].waitForExistence(timeout: 2), file: file, line: line)
        let bar = app.navigationBars["推し活カウントダウン"]
        XCTAssertTrue(bar.exists, file: file, line: line)
        XCTAssertFalse(bar.staticTexts["推し活カウントダウン"].exists, file: file, line: line)
    }

    @MainActor
    func testRegisterEditAndDeleteOshi() throws {
        let app = launch(hasCompletedOnboarding: true)
        app.selectTab("推し")
        XCTAssertTrue(app.staticTexts["推しを登録しよう"].waitForExistence(timeout: 2))

        // 登録する
        app.navigationBars["推し"].buttons["推しを登録"].tap()
        XCTAssertTrue(app.navigationBars["推しを登録"].waitForExistence(timeout: 2))
        let save = app.navigationBars["推しを登録"].buttons["保存"]
        XCTAssertFalse(save.isEnabled)
        let name = app.textFields["推しの名前"]
        name.tap()
        name.typeText("ミナト")
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch.waitForExistence(timeout: 2))
        // 行は名前と予定の件数をまとめて読み上げる
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "予定 0 件")).firstMatch.exists)

        // 編集して名前を変える
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナト")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["推しを編集"].waitForExistence(timeout: 2))
        let editingName = app.textFields["推しの名前"]
        editingName.tap()
        editingName.typeText("くん")
        app.navigationBars["推しを編集"].buttons["保存"].tap()
        let renamed = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "ミナトくん")).firstMatch
        XCTAssertTrue(renamed.waitForExistence(timeout: 2))

        // 削除する
        renamed.tap()
        XCTAssertTrue(app.navigationBars["推しを編集"].waitForExistence(timeout: 2))
        app.buttons["推しを削除"].tap()
        let alert = app.alerts["「ミナトくん」を削除しますか？"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        XCTAssertTrue(alert.staticTexts["元に戻せません。"].exists)
        alert.buttons["削除"].tap()
        XCTAssertTrue(app.staticTexts["推しを登録しよう"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testReorderOshis() throws {
        let app = launch(hasCompletedOnboarding: true, arguments: ["-seedSampleData"])
        app.selectTab("推し")
        let rows = app.buttons.matching(identifier: "oshiList.row")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(rows.element(boundBy: 0).label.contains("LUMINA"))
        XCTAssertTrue(rows.element(boundBy: 2).label.contains("レオ"))

        // ふつうの一覧では、並べ替えの案内も順位も出さない
        let guide = app.descendants(matching: .any).matching(identifier: "oshiList.reorderGuide").firstMatch
        XCTAssertFalse(guide.exists)
        XCTAssertFalse(rows.element(boundBy: 0).label.contains("1 位"))

        // 並べ替えの間は、一覧の上に案内・行に順位を出し、登録のボタンを押せない
        app.navigationBars["推し"].buttons["並べ替え"].tap()
        let confirm = app.navigationBars["推し"].buttons["この順番で確定"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 2))
        XCTAssertTrue(guide.waitForExistence(timeout: 2))
        XCTAssertTrue(guide.label.contains("並べ替え中"))
        XCTAssertTrue(rows.element(boundBy: 0).label.contains("1 位"))
        XCTAssertTrue(rows.element(boundBy: 2).label.contains("3 位"))
        XCTAssertFalse(app.navigationBars["推し"].buttons["推しを登録"].isEnabled)

        // 3 番目（レオ）の行の右端の並べ替えの印を、いちばん上の行までドラッグする。
        // 一覧の上に案内の行があるので、推しの行の入ったセルだけを数える
        let cells = app.cells.containing(.button, identifier: "oshiList.row")
        let handle = cells.element(boundBy: 2).coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        let top = cells.element(boundBy: 0).coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.2))
        // ゆっくり引き、いちばん上で止めてから離す。遅い CI の Simulator では、着いてすぐ指を離すと、
        // ほかの行がよける前に落ちて 2 位に入った（#317）。落とした後に一覧が並べ替えた順になるまでも、4 秒ほどかかった
        handle.press(forDuration: 0.5, thenDragTo: top, withVelocity: .slow, thenHoldForDuration: 1)
        let first = rows.element(boundBy: 0)
        let deadline = Date().addingTimeInterval(10)
        while !first.label.contains("レオ"), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertTrue(first.label.contains("レオ"))
        // 順位は並べ替えた順で数え直す
        XCTAssertTrue(first.label.contains("1 位"))
        XCTAssertTrue(rows.element(boundBy: 1).label.contains("LUMINA"))
        XCTAssertTrue(rows.element(boundBy: 1).label.contains("2 位"))
        confirm.tap()
        XCTAssertTrue(app.navigationBars["推し"].buttons["並べ替え"].waitForExistence(timeout: 2))
        XCTAssertTrue(guide.waitForNonExistence(timeout: 2))

        // ホームの推しの絞り込みも、並べ替えた順になる
        app.selectTab("ホーム")
        let leo = app.buttons["レオ"]
        XCTAssertTrue(leo.waitForExistence(timeout: 5))
        XCTAssertLessThan(leo.frame.minX, app.buttons["LUMINA"].frame.minX)
    }

    @MainActor
    func testSettingsShowsPastEventsToggleAndLicenses() throws {
        let app = launch(hasCompletedOnboarding: true)
        app.selectTab("設定")
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 2))

        let showsPast = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "終わった予定も表示する")).firstMatch
        XCTAssertTrue(showsPast.exists)
        XCTAssertEqual(showsPast.value as? String, "0")
        // 通知の欄の下にあるので、画面の外なら下まで送る
        let version = app.staticTexts["バージョン"]
        if !version.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(version.waitForExistence(timeout: 2))

        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "オープンソースライセンス")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["オープンソースライセンス"].waitForExistence(timeout: 2))
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Outfit")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Outfit"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "SIL OPEN FONT LICENSE")).firstMatch.exists)
    }

    @MainActor
    func testSettingsReminderTimings() throws {
        let app = launch(hasCompletedOnboarding: true)
        app.selectTab("設定")
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 2))

        // 既定は通知を ON にし、5 つのタイミングをすべて出す
        let reminders = app.switches["settings.reminders"]
        XCTAssertTrue(reminders.waitForExistence(timeout: 2))
        XCTAssertEqual(reminders.value as? String, "1")
        // 上に Plus と着せ替えの行があり、通知の欄の下のほうは画面の外になる（Form は画面の外の行を作らない）ので、見えるところまで送る
        for timing in ["thirtyDaysBefore", "sevenDaysBefore", "dayBefore", "onTheDay", "hourBeforeStart"] {
            let toggle = app.switches["settings.reminderTiming.\(timing)"]
            scrollIntoView(toggle, in: app, upward: true)
            XCTAssertTrue(toggle.exists, timing)
            XCTAssertEqual(toggle.value as? String, "1", timing)
        }
        scrollIntoView(app.datePickers.firstMatch, in: app, upward: true)
        XCTAssertTrue(app.datePickers.firstMatch.exists)

        // OFF にすると、タイミングと時刻の項目を隠す
        // いちばん上まで戻し、送った後の惰性が止まってから押す（動いている間に押すと、スクロールが止まるだけでスイッチが切り替わらない）
        app.swipeDown()
        app.swipeDown()
        scrollIntoView(reminders, in: app, upward: false)
        reminders.waitUntilStill()
        XCTAssertTrue(reminders.isHittable)
        reminders.setSwitch(to: "0")
        XCTAssertTrue(app.switches["settings.reminderTiming.thirtyDaysBefore"].waitForNonExistence(timeout: 2))
        XCTAssertFalse(app.datePickers.firstMatch.exists)
    }

    /// `element` が画面の中で押せるところに来るまで、ゆっくり送る（`upward` が true なら下の行へ、false なら上の行へ）。何度か送っても来なければそのまま返す。
    @MainActor
    private func scrollIntoView(_ element: XCUIElement, in app: XCUIApplication, upward: Bool, maxSwipes: Int = 5) {
        var swipes = 0
        while !(element.exists && element.isHittable), swipes < maxSwipes {
            if upward {
                app.swipeUp(velocity: .slow)
            } else {
                app.swipeDown(velocity: .slow)
            }
            swipes += 1
        }
    }

    /// 通知を押すと、その予定の詳細が開く（落ちない。#186）。
    /// メモリ上のストアでは予約しないので、裏に回ったらテスト用の通知を出す口（`-scheduleTestReminder`）を使う。
    @MainActor
    func testTappingReminderOpensEventDetail() throws {
        let app = launch(hasCompletedOnboarding: true, arguments: ["-scheduleTestReminder"])
        XCTAssertTrue(app.buttons["home.addEvent"].waitForExistence(timeout: 5))
        app.buttons["home.addEvent"].tap()
        let title = app.textFields["タイトル"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        title.tap()
        title.typeText("通知の予定")
        app.navigationBars["予定を追加"].buttons["保存"].tap()

        // まだ聞いていなければ、保存の直後に通知の許可を求められる
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.alerts.buttons.matching(NSPredicate(format: "label IN %@", ["許可", "Allow"])).firstMatch
        if allow.waitForExistence(timeout: 5) {
            allow.tap()
        }
        XCTAssertTrue(app.staticTexts["通知の予定"].waitForExistence(timeout: 2))

        // 裏に回ると 2 秒後に通知が出るので、バナーを押す
        XCUIDevice.shared.press(.home)
        let banner = springboard.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "通知の予定")).firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 15))
        banner.tap()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.staticTexts["今日は当日！"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testAddEventFromHome() throws {
        let app = launch(hasCompletedOnboarding: true)
        XCTAssertTrue(app.staticTexts["まだ予定がありません"].waitForExistence(timeout: 5))

        app.buttons["home.addEvent"].tap()
        XCTAssertTrue(app.navigationBars["予定を追加"].waitForExistence(timeout: 2))
        let save = app.navigationBars["予定を追加"].buttons["保存"]
        XCTAssertFalse(save.isEnabled)
        let title = app.textFields["タイトル"]
        title.tap()
        title.typeText("5th LIVE")
        XCTAssertTrue(save.isEnabled)
        save.tap()

        // 今日の予定なので、先頭のカードと、これからの予定の行に「今日！」で出る
        let featured = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "いちばん近い予定")).firstMatch
        XCTAssertTrue(featured.waitForExistence(timeout: 2))
        XCTAssertTrue(featured.label.contains("5th LIVE"))
        XCTAssertTrue(featured.label.contains("今日！"))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "5th LIVE、")).firstMatch.exists)
    }

    @MainActor
    func testEventDetailPinsAndDeletes() throws {
        let app = launch(hasCompletedOnboarding: true)
        XCTAssertTrue(app.staticTexts["まだ予定がありません"].waitForExistence(timeout: 5))
        app.buttons["home.addEvent"].tap()
        let title = app.textFields["タイトル"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        title.tap()
        title.typeText("5th LIVE")
        app.navigationBars["予定を追加"].buttons["保存"].tap()

        // 行から詳細を開く。今日の時刻の無い予定なので当日
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "5th LIVE、")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        // 当日の表示は「今日は当日！」と「楽しんできてね」をまとめて読み上げる 1 つの要素
        let today = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "今日は当日！")).firstMatch
        XCTAssertTrue(today.waitForExistence(timeout: 2))

        // ピン留めを切り替える
        app.buttons["ピン留めする"].tap()
        XCTAssertTrue(app.buttons["ピン留めを外す"].waitForExistence(timeout: 2))

        // 削除するとホームに戻る
        app.buttons["その他の操作"].tap()
        app.buttons["予定を削除"].tap()
        let alert = app.alerts["この予定を削除しますか？"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        XCTAssertTrue(alert.staticTexts["「5th LIVE」を削除します。元に戻せません。"].exists)
        alert.buttons["削除"].tap()
        XCTAssertTrue(app.staticTexts["まだ予定がありません"].waitForExistence(timeout: 3))
        // 詳細から戻っても、バーにタイトルの文字は出ない
        assertShowsHome(app)
    }

    /// iPad のサイドバーで、予定の詳細を開いたまま推し・設定に切り替えても落ちない（#331）。ホームに戻ると最初の画面になる。
    /// サイドバーは iPad の広い画面だけなので、iPhone（CI の Simulator）では飛ばす
    @MainActor
    func testSidebarSwitchWhileEventDetailIsOpen() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "サイドバーは iPad の広い画面だけ")
        let app = launch(hasCompletedOnboarding: true, arguments: ["-seedSampleData"])
        let featured = app.buttons["home.featuredEvent"].firstMatch
        XCTAssertTrue(featured.waitForExistence(timeout: 5))
        featured.tap()
        XCTAssertTrue(app.buttons["eventDetail.pin"].waitForExistence(timeout: 5))

        selectSidebarItem(at: 1, in: app)
        XCTAssertTrue(app.buttons["oshiList.row"].firstMatch.waitForExistence(timeout: 5))
        selectSidebarItem(at: 2, in: app)
        XCTAssertTrue(app.switches["settings.reminders"].waitForExistence(timeout: 5))

        selectSidebarItem(at: 0, in: app)
        XCTAssertTrue(featured.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["eventDetail.pin"].exists)
        XCTAssertEqual(app.state, .runningForeground)
    }

    /// サイドバーの `index` 番目（ホーム・推し・設定の順）を押す。行の ID（`sidebar.<タブ>`）で探す。
    /// 並びの位置では探さない（右の列の一覧もセルを持つので、取り違える）。縦向きでサイドバーが隠れていたら出してから押す
    @MainActor
    private func selectSidebarItem(at index: Int, in app: XCUIApplication) {
        // 行の ID は、行の文字にもアイコンの画像にも付く（画像は押せない）ので、文字を探す
        let item = app.staticTexts["sidebar.\(["home", "oshi", "settings"][index])"].firstMatch
        if !(item.exists && item.isHittable) {
            let toggle = app.buttons["ToggleSidebar"].firstMatch
            if toggle.exists {
                toggle.tap()
            }
        }
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()
    }
}
