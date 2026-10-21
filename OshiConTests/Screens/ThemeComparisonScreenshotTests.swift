//
//  ThemeComparisonScreenshotTests.swift
//  OshiConTests
//

@testable import OshiCon
import SwiftUI
import UIKit
import XCTest

/// テーマ案を横に並べて比べる見本（`ThemeComparisonBoard`）を PNG に撮る（README の「テーマの見本」）。
///
/// ふだんのテストでは流さない。環境変数 `THEME_SCREENSHOTS=1`（xcodebuild には `TEST_RUNNER_THEME_SCREENSHOTS=1`）のときだけ流れ、
/// 外観は `THEME_APPEARANCE`（`light` / `dark`。無ければライト）で選ぶ。日本語の書体を見るときは日本語で流す（`-testLanguage ja`）。
nonisolated final class ThemeComparisonScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["THEME_SCREENSHOTS"] == "1",
            "テーマの見本は README の「テーマの見本」の手順で撮る"
        )
    }

    @MainActor
    func testCaptureComparison() throws {
        let environment = ProcessInfo.processInfo.environment
        let colorScheme: ColorScheme = environment["THEME_APPEARANCE"] == "dark" ? .dark : .light
        let renderer = ImageRenderer(content: ThemeComparisonBoard().environment(\.colorScheme, colorScheme))
        // 6 列で横に長いので、ウィジェットの撮影（3 倍）より小さく 2 倍で撮る
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.uiImage)
        let attachment = XCTAttachment(data: try XCTUnwrap(image.pngData()), uniformTypeIdentifier: "public.png")
        attachment.name = "07-テーマ案を並べる"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
