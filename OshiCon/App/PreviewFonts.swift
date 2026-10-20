//
//  PreviewFonts.swift
//  OshiCon
//

import CoreText
import Foundation

/// テーマ案の日本語の書体（Preview・DEBUG の見本・テストだけで使う。どれも SIL OFL 1.1）。
///
/// ファイルは `OshiCon/Preview Content/Fonts/` にあり（`DEVELOPMENT_ASSET_PATHS` なので Archive には入らない）、
/// `UIAppFonts` に足さずに、ここで process の範囲に登録する。出荷するアプリではファイルが無いので何もしない。
nonisolated enum PreviewFonts {
    /// 書体のファイル（拡張子 `.ttf`）。ファイル名は PostScript 名と同じ。
    static let fileNames = [
        "KiwiMaru-Regular",
        "KiwiMaru-Medium",
        "ZenMaruGothic-Regular",
        "ZenMaruGothic-Bold",
        "ZenKakuGothicNew-Light",
        "KaiseiDecol-Regular",
        "KaiseiDecol-Bold",
        "MochiyPopOne-Regular"
    ]

    /// ライセンス文（拡張子 `.txt`。google/fonts の `OFL.txt` のまま）。
    /// Zen Kaku Gothic New の分は、同梱の書体と同じ文の `ZenKakuGothicNew-OFL.txt`（`Shared/Resources/Fonts/`）を使う。
    static let licenseFileNames = [
        "KiwiMaru-OFL",
        "ZenMaruGothic-OFL",
        "ZenKakuGothicNew-OFL",
        "KaiseiDecol-OFL",
        "MochiyPopOne-OFL"
    ]

    /// 書体を登録する。何度呼んでも登録は 1 回。ファイルが無ければ何もしない。
    static func registerIfNeeded() {
        _ = registration
    }

    /// バンドルにある書体のファイル。
    static func fontURLs(in bundle: Bundle = .main) -> [URL] {
        fileNames.compactMap { bundle.url(forResource: $0, withExtension: "ttf") }
    }

    private static let registration: Void = {
        for url in fontURLs() {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
