//
//  ThemeWidgetScreenshotTests.swift
//  OshiConTests
//

@testable import OshiCon
import SwiftUI
import UIKit
import XCTest

/// テーマ案の見本のウィジェット 2 種を、ウィジェットの大きさの枠に入れて PNG に撮る（README の「テーマの見本」）。
///
/// ふだんのテストでは流さない。環境変数 `THEME_SCREENSHOTS=1`（xcodebuild には `TEST_RUNNER_THEME_SCREENSHOTS=1`）のときだけ流れ、
/// テーマは `THEME_ID`（`AppTheme` の id。無ければ既定のテーマ）で選ぶ。ライト / ダークは Simulator の外観に合わせる。
/// 文言はアプリの言語（Simulator の言語）で出るので、日本語の書体を見るときは Simulator の言語を日本語にしておく。
nonisolated final class ThemeWidgetScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["THEME_SCREENSHOTS"] == "1",
            "テーマの見本は README の「テーマの見本」の手順で撮る"
        )
    }

    @MainActor
    func testCaptureWidgets() throws {
        PreviewFonts.registerIfNeeded()
        let theme = AppTheme.theme(id: ProcessInfo.processInfo.environment["THEME_ID"] ?? AppTheme.standard.id)
        let colorScheme: ColorScheme = UIScreen.main.traitCollection.userInterfaceStyle == .dark ? .dark : .light
        try capture("05-ウィジェット-カウントダウン", WidgetPreview.countdown(.sample, theme: theme), colorScheme: colorScheme)
        try capture("06-ウィジェット-推しカウント", WidgetPreview.upcoming(.sample, theme: theme), colorScheme: colorScheme)
    }

    @MainActor
    private func capture(_ name: String, _ view: some View, colorScheme: ColorScheme) throws {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, colorScheme))
        renderer.scale = 3
        let image = try XCTUnwrap(renderer.uiImage)
        let attachment = XCTAttachment(data: try XCTUnwrap(image.pngData()), uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
