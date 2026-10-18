//
//  OshiConUITestsLaunchTests.swift
//  OshiConUITests
//
//  Created by 村石 拓海 on 2024/05/12.
//

import XCTest

final class OshiConUITestsLaunchTests: XCTestCase {
    override static var runsForEachTargetApplicationUIConfiguration: Bool {
        true
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
