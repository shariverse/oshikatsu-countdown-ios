//
//  OshiConUITestsLaunchTests.swift
//  OshiConUITests
//
//  Created by 村石 拓海 on 2024/05/12.
//

import XCTest

final class OshiConUITestsLaunchTests: XCTestCase {
    /// 端末の向き・外観・言語の組み合わせごとには流さない（12 言語に対応してから組み合わせが 170 通りを超え、CI の制限時間を超えるため）。
    /// 起動は日本語に固定しているので、言語ごとに流しても同じ画面になる。
    override static var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        // 文言で要素を探すので、Simulator の言語にかかわらず日本語で起動する
        app.launchArguments = ["-useInMemoryStore", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()

        // 起動直後のスクリーンショットをテスト結果に添付する
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
