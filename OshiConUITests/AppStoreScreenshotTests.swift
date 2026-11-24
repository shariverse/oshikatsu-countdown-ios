//
//  AppStoreScreenshotTests.swift
//  OshiConUITests
//

import XCTest

/// App Store 用スクリーンショットの元になる画面を撮る。見本の推しと予定（`-seedSampleData`）で起動し、画面を添付ファイルとして残す。
///
/// 撮った画面は、そのまま App Store に載せず、`scripts/app-store-screenshots.sh` が見出しと端末の枠を付けて 10 枚にする
/// （docs/app-store/screenshots/screenshots.html。どの画面をどの枚に使うかもそこで決める）。添付の名前は、そこで使う名前と同じにする。
///
/// - アプリの中の画面は、Simulator で動かした実物を撮る（審査ガイドライン 2.3）。画面は端末の設定（ダーク）で、推し色のテーマとホームの 1 枚はライトに固定する
/// - アプリの外の面のうち、ライブアクティビティ（ロック画面・Dynamic Island）と通知は、見本の予定で実際に出して撮る
///   （`-sampleLiveActivity`・`-sampleReminders`）。ウィジェットとロック画面のアクセサリは置けないので、
///   ホーム画面・ロック画面だけを撮り、ウィジェットは `AppStoreSurfaceRenderingTests` が本物の View から描き出したものを重ねる。
///   重ねる位置のため、ホーム画面のアイコンの位置を `home-screen-layout`（JSON）に残す
///
/// ふだんのテストでは流さない。`scripts/app-store-screenshots.sh` が環境変数 `APP_STORE_SCREENSHOTS=1`
/// （xcodebuild には `TEST_RUNNER_APP_STORE_SCREENSHOTS=1` で渡す）を付けて、表示サイズ・言語ごとに流す。
/// 言語は `APP_STORE_LANGUAGE`（`-AppleLanguages` の値）と `APP_STORE_LOCALE`（`-AppleLocale` の値）で受け取る。
/// 文言は言語で変わるので、要素はアクセシビリティ ID と並びの位置で探す。
/// 戻るボタンやサイドバーの並びは iPhone と iPad で違うので、画面ごとに起動し直してから開く。
final class AppStoreScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["APP_STORE_SCREENSHOTS"] == "1",
            "App Store 用スクリーンショットは scripts/app-store-screenshots.sh で撮る"
        )
        continueAfterFailure = false
    }

    /// 画面が出るのを待つ秒数。CI や重い Mac では、起動したばかりのアプリの最初の画面が 5 秒では出ないことがある
    private static let timeout: TimeInterval = 15

    /// 1 位の推しを替えて撮るテーマの色（`SampleData.Role` の生の値）。ピンク（既定の 1 位）に偏らないよう、ほかの 3 色にする。
    private static let themeRoles = ["singer", "voice-actor", "streamer"]

    /// アプリの中の画面。スクリプトはステータスバーをそろえてから流す。アプリの外の面より先に流す（ライブアクティビティの Dynamic Island が写らないうちに）
    @MainActor
    func testCaptureScreensInApp() throws {
        captureScreensInApp()
        capturePlusAppearance()
    }

    /// アプリの外の面（ホーム画面・ロック画面）。ステータスバーを上書きしているとロック画面の日付が 1 月 1 日になるので、
    /// スクリプトは上書きを外してから流す
    @MainActor
    func testCaptureSurfacesOutsideApp() throws {
        captureSurfacesOutsideApp()
    }

    /// アプリの中の画面（無料の機能）。
    @MainActor
    private func captureScreensInApp() {
        // 予定の詳細: 当日の配信（開始の 40 分ほど前。秒まで進む）
        var app = launch()
        let row = app.buttons["home.eventRow"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: Self.timeout))
        row.tap()
        XCTAssertTrue(app.buttons["eventDetail.pin"].waitForExistence(timeout: Self.timeout))
        capture("detail")

        // 画像でシェア: ピン留めのライブ
        app = launch()
        let featured = featuredCard(in: app)
        XCTAssertTrue(featured.waitForExistence(timeout: Self.timeout))
        featured.tap()
        let share = app.buttons["eventDetail.share"]
        XCTAssertTrue(share.waitForExistence(timeout: Self.timeout))
        share.tap()
        // シートが上がりきり、カードの写真が描かれるのを待つ
        Thread.sleep(forTimeInterval: 2)
        capture("share-card")

        // 推し色のテーマ: 1 位の推しを替えて、ライトの外観のホームを 3 色撮る
        for (index, role) in Self.themeRoles.enumerated() {
            // テーマの地の色は、ライトの外観のほうがよくわかる
            app = launch(["-sampleTopOshi", role, "-colorScheme", "light"])
            XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: Self.timeout))
            capture("theme-\(index + 1)")
        }

        // 推しの一覧
        app = launch()
        XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: Self.timeout))
        openSection(.oshi, in: app)
        XCTAssertTrue(app.buttons["oshiList.row"].firstMatch.waitForExistence(timeout: Self.timeout))
        capture("oshi-list")

        // ライトの外観のホーム
        app = launch(["-colorScheme", "light"])
        XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: Self.timeout))
        capture("home-light")
    }

    /// Plus の着せ替え。
    @MainActor
    private func capturePlusAppearance() {
        // Plus: 着せ替え（背景の写真と飾り）のホームと、着せ替えの画面
        let app = launch(["-sampleAppearance"], plus: true)
        XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: Self.timeout))
        XCTAssertTrue(app.descendants(matching: .any)["home.appearance"].firstMatch.waitForExistence(timeout: Self.timeout))
        // 背景の写真の取り込みと、ぼかしが描かれるのを待つ
        Thread.sleep(forTimeInterval: 2)
        capture("appearance-home")
        openSection(.settings, in: app)
        let appearanceRow = app.buttons["settings.appearance"]
        XCTAssertTrue(appearanceRow.waitForExistence(timeout: Self.timeout))
        appearanceRow.tap()
        XCTAssertTrue(app.descendants(matching: .any)["appearance.preview"].firstMatch.waitForExistence(timeout: Self.timeout))
        Thread.sleep(forTimeInterval: 1)
        capture("appearance-settings")
    }

    /// アプリの外の面。
    @MainActor
    private func captureSurfacesOutsideApp() {
        // アプリの外: ロック画面（ライブアクティビティ）とホーム画面（Dynamic Island のライブアクティビティ）
        var app = launch(["-sampleLiveActivity"])
        XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: Self.timeout))
        Thread.sleep(forTimeInterval: 2)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        lockAndWake()
        // iOS 27 は、アプリのライブアクティビティを初めて出すとき、ロック画面で許可を求める
        allowLiveActivitiesIfAsked(on: springboard)
        capture("lock-screen")
        // ロックを解くとアプリに戻るので、ホームボタンでホーム画面に出る
        unlock()
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(springboard.icons.firstMatch.waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 2)
        capture("home-screen")
        attachHomeScreenLayout(of: springboard)

        // アプリの外: ロック画面の通知（見本の予定の通知の計画の先頭の数件を、実際の文面で出す）。ライブアクティビティは終える
        app = launch(["-sampleReminders"])
        allowNotificationsIfAsked(in: app)
        XCTAssertTrue(featuredCard(in: app).waitForExistence(timeout: Self.timeout))
        Thread.sleep(forTimeInterval: 1)
        lockAndWake(waitingFor: 6)
        capture("lock-notifications")
        unlock()
    }

    /// 端末をロックし、画面を点けてロック画面を出す。`seconds` 秒待ってから戻る（通知が届くのを待つ）。
    /// ロックのボタンは XCUIDevice の公開の API に無いので、ボタンを押す口（`pressLockButton`）を使う。
    @MainActor
    private func lockAndWake(waitingFor seconds: TimeInterval = 2) {
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        Thread.sleep(forTimeInterval: 1.5)
        // ロック中にホームボタンを 1 回押すと、ロックを解かずに画面だけ点く
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: seconds)
    }

    /// ロックを解く（パスコードは無い）。ロック中にアプリを起動すると前面に来ないので、次の画面の前に解く。
    @MainActor
    private func unlock() {
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// ロック画面のライブアクティビティで許可を求められたら許可する。ボタンの文言は言語で変わるので、
    /// 画面の下半分で横に並んだボタンの右（許可）を押す。求められなければ何もしない。
    @MainActor
    private func allowLiveActivitiesIfAsked(on springboard: XCUIApplication) {
        let height = XCUIScreen.main.screenshot().image.size.height
        let buttons = springboard.buttons.allElementsBoundByIndex.filter { button in
            button.exists && button.isHittable && button.frame.minY > height / 2
        }
        let rows = Dictionary(grouping: buttons) { Int($0.frame.minY.rounded()) }
        guard let pair = rows.values.first(where: { $0.count == 2 }),
              let allow = pair.max(by: { $0.frame.minX < $1.frame.minX }) else {
            return
        }
        allow.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// 通知の許可のダイアログの「許可」の文言（docs/app-store/languages.json の 12 言語）。iOS 27 のダイアログは alert の要素として見えないので、文言で探す
    private static let allowLabels = ["許可", "Allow", "允许", "允許", "허용", "Autoriser", "Erlauben", "Permitir", "Consenti", "อนุญาต", "Izinkan"]

    /// 通知の許可を聞かれたら許可する。ボタンはホーム画面（SpringBoard）かアプリの要素として見えるので、両方を探す。
    /// iOS 26 は alert の右のボタン、iOS 27 は「許可」の文言のボタンを押す。見つからなければ、次に直せるよう要素の一覧をログに残す
    @MainActor
    private func allowNotificationsIfAsked(in app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deadline = Date().addingTimeInterval(Self.timeout)
        let isAllow = NSPredicate(format: "label IN %@", Self.allowLabels)
        while Date() < deadline {
            if let alert = [springboard.alerts.firstMatch, app.alerts.firstMatch].first(where: \.exists) {
                let buttons = alert.buttons
                buttons.element(boundBy: buttons.count - 1).tap()
                return
            }
            let candidates = [springboard.buttons.matching(isAllow).firstMatch, app.buttons.matching(isAllow).firstMatch]
            if let allow = candidates.first(where: { $0.exists && $0.isHittable }) {
                allow.tap()
                return
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        print("通知の許可のダイアログが見つかりません\n\(springboard.debugDescription)\n\(app.debugDescription)")
    }

    /// ホーム画面のアイコンの位置（ポイント）とラベルを `home-screen-layout` の JSON に残す。ウィジェットを重ねる位置を、アイコンの並びと
    /// テストのランナーのアイコンの位置から決める（ランナーのアイコンは、ウィジェットで覆って写さない）。
    @MainActor
    private func attachHomeScreenLayout(of springboard: XCUIApplication) {
        let screen = XCUIScreen.main.screenshot().image.size
        let bounds = CGRect(origin: .zero, size: screen)
        // 画面の外（ほかのページ）のアイコンは除く
        let elements: [XCUIElement] = springboard.icons.allElementsBoundByIndex.filter { icon in
            !icon.frame.isEmpty && bounds.contains(icon.frame)
        }
        let icons: [[String: Any]] = elements.map { icon in
            let frame = icon.frame
            return ["x": frame.minX, "y": frame.minY, "width": frame.width, "height": frame.height, "label": icon.label]
        }
        let size: [String: Double] = ["width": screen.width, "height": screen.height]
        let layout: [String: Any] = ["screen": size, "icons": icons]
        guard let data = try? JSONSerialization.data(withJSONObject: layout, options: [.prettyPrinted, .sortedKeys]) else {
            XCTFail("ホーム画面のアイコンの位置を書けませんでした")
            return
        }
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        attachment.name = "home-screen-layout"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 見本のデータで起動し直す（動いていれば終わらせてから起動する）。システムの文言もその言語になるよう、言語と地域も渡す。
    /// 当日の配信は、今から 40 分ほど先に始まるようにする（`-sampleStreamStartsSoon`。詳細とライブアクティビティで秒まで数える）。
    /// 配るアプリと同じ画面にするため、App Store 版として動かす（`-simulateAppStoreDistribution`。1.3.0 から設定に Plus・着せ替えの行も出る）。
    /// 無料の機能の画面では、Plus は使えない状態に固定する（`-plusLocked`。StoreKit に問い合わせない）。
    /// `plus` のときは、Plus を使える状態にする（`-plusUnlocked`）。
    /// 見本の推しには、このテストのバンドルにある写真（`SampleOshiPhotos/`）を付ける（`OSHICON_SAMPLE_OSHI_PHOTOS`）。
    @MainActor
    private func launch(_ extraArguments: [String] = [], plus: Bool = false) -> XCUIApplication {
        let environment = ProcessInfo.processInfo.environment
        let language = environment["APP_STORE_LANGUAGE"] ?? "ja"
        let locale = environment["APP_STORE_LOCALE"] ?? "ja_JP"
        let app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-sampleStreamStartsSoon",
            "-hasCompletedOnboarding", "YES",
            "-showsPastEvents", "NO",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "-simulateAppStoreDistribution"
        ] + (plus ? ["-plusUnlocked"] : ["-plusLocked"]) + extraArguments
        if let directory = sampleOshiPhotosDirectory {
            app.launchEnvironment["OSHICON_SAMPLE_OSHI_PHOTOS"] = directory.path(percentEncoded: false)
        } else {
            XCTFail("見本の推しの写真（sample-oshi-*.jpg）がテストのバンドルにありません")
        }
        app.launch()
        return app
    }

    /// 見本の推しの写真（`sample-oshi-<役どころ>.jpg`。アプリの `SampleData.Role`）を置いた、テストのバンドルの中のディレクトリ。
    /// Simulator のアプリはホストのファイルを読めるので、場所だけを渡す（写真をアプリに入れず、アプリの容量を増やさない）。
    private var sampleOshiPhotosDirectory: URL? {
        let bundle = Bundle(for: Self.self)
        let photo = bundle.url(forResource: "sample-oshi-group", withExtension: "jpg")
            ?? bundle.url(forResource: "sample-oshi-group", withExtension: "jpg", subdirectory: "SampleOshiPhotos")
        return photo?.deletingLastPathComponent()
    }

    /// 先頭のカード（ピン留めした予定へのリンク）。
    @MainActor
    private func featuredCard(in app: XCUIApplication) -> XCUIElement {
        app.buttons["home.featuredEvent"].firstMatch
    }

    /// タブ（並びは AppTab と同じ）。
    private enum Section: Int {
        case home
        case oshi
        case settings

        /// タブのアイコン（AppTab.systemImage）。iOS 27 の iPhone Duo の縦のタブは、このアイコン名を ID に持つボタンになる
        var systemImage: String {
            switch self {
            case .home: "house"
            case .oshi: "heart"
            case .settings: "gearshape"
            }
        }
    }

    /// iPhone はタブバー、iPad はサイドバー、iPhone Duo（iOS 27）は縦のタブで切り替える。サイドバーが隠れていたら出してから押す。
    @MainActor
    private func openSection(_ section: Section, in app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons.element(boundBy: section.rawValue).tap()
            return
        }
        if sidebarItem(section, in: app) == nil {
            let toggle = app.buttons["ToggleSidebar"].firstMatch
            if toggle.exists {
                toggle.tap()
            }
        }
        // サイドバーの項目の要素の種類は OS や機種で変わる（iOS 26 の iPad は collection view のセルで、行に付けた ID が届かない）
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if let item = sidebarItem(section, in: app) {
                item.tap()
                return
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        // 見つからなかったときは、次に直せるよう画面の要素の一覧をログに残す
        print(app.debugDescription)
        XCTFail("サイドバーの項目 \(section) が見つかりません")
    }

    /// サイドバー・縦のタブの項目。縦のタブのアイコン名、ID、並びの位置（collection view・table・outline のセル）の順に探し、押せるものを返す。
    @MainActor
    private func sidebarItem(_ section: Section, in app: XCUIApplication) -> XCUIElement? {
        let candidates = [
            app.buttons[section.systemImage].firstMatch,
            app.descendants(matching: .any)["sidebar.\(section)"].firstMatch,
            app.collectionViews.firstMatch.cells.element(boundBy: section.rawValue),
            app.tables.firstMatch.cells.element(boundBy: section.rawValue),
            app.outlines.firstMatch.cells.element(boundBy: section.rawValue)
        ]
        return candidates.first { $0.exists && $0.isHittable }
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
