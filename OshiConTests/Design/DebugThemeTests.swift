//
//  DebugThemeTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct DebugThemeTests {
    /// テストごとの一時的な場所（App Group のコンテナのファイルは書き換えない）。
    private let url = FileManager.default.temporaryDirectory
        .appending(path: "DebugThemeTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        .appending(path: "debug-theme-id", directoryHint: .notDirectory)

    @Test("書いた id のテーマをウィジェットで読める", arguments: AppTheme.all)
    func roundTrip(theme: AppTheme) {
        DebugTheme.write(id: theme.id, to: url)
        #expect(DebugTheme.storedTheme(at: url) == theme)
    }

    @Test("ファイルが無いときと知らない id のときは既定のテーマ")
    func fallsBackToStandard() {
        #expect(DebugTheme.storedTheme(at: url) == .standard)
        DebugTheme.write(id: "unknownTheme", to: url)
        #expect(DebugTheme.storedTheme(at: url) == .standard)
    }

    @Test("ウィジェットの書体はアプリのバンドルから読む（アプリでは自分のバンドル）")
    func fontBundleIsApp() {
        #expect(PreviewFonts.fontBundle == .main)
        #expect(PreviewFonts.fontURLs(in: PreviewFonts.fontBundle).count == PreviewFonts.fileNames.count)
    }
}
