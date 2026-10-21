//
//  DebugTheme.swift
//  OshiCon
//

import Foundation
import os

/// デバッグ用のテーマの切り替え。TestFlight でテーマ案を実機で比べるためのもので、確認用のブランチ（`testflight/theme-trial`）だけに置く
/// （epic・`develop` にはマージしない。出荷するアプリは既定のテーマだけを使う）。
///
/// 設定の「デバッグ」で選んだテーマの id をアプリの UserDefaults（`storageKey`）に持ち、ウィジェットに渡すため App Group のコンテナのファイルにも書く。
/// App Group の `UserDefaults(suiteName:)` はプライバシーマニフェストの申告（`1C8F.1`）が要るので使わない。
nonisolated enum DebugTheme {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "DebugTheme")

    /// アプリの UserDefaults のキー。設定の Picker とアプリの入口が `@AppStorage` で読み書きする。
    static let storageKey = "debugThemeID"

    /// ウィジェットに渡すファイル（App Group のコンテナ）。
    static var fileURL: URL {
        AppGroupContainer.dataDirectory.appending(path: "debug-theme-id", directoryHint: .notDirectory)
    }

    /// id のテーマ。案のテーマなら、書体を使う前に登録する（何度呼んでも登録は 1 回）。
    static func theme(id: String) -> AppTheme {
        let theme = AppTheme.theme(id: id)
        if theme != .standard {
            PreviewFonts.registerIfNeeded()
        }
        return theme
    }

    /// 選んだテーマの id をファイルに書く（アプリから）。
    static func write(id: String, to url: URL = fileURL) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(id.utf8).write(to: url, options: .atomic)
        } catch {
            logger.error("デバッグ用のテーマを書けなかった: \(error.localizedDescription)")
        }
    }

    /// ファイルに書かれたテーマ（ウィジェットから）。ファイルが無い・読めないときは既定のテーマ。
    static func storedTheme(at url: URL = fileURL) -> AppTheme {
        guard let id = try? String(contentsOf: url, encoding: .utf8) else {
            return .standard
        }
        return theme(id: id.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
