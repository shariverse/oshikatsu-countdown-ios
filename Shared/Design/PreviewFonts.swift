//
//  PreviewFonts.swift
//  OshiCon
//

import CoreText
import Foundation

/// テーマ案の日本語の書体（Preview・DEBUG の見本・テストだけで使う。どれも SIL OFL 1.1）。
///
/// ファイルは `OshiCon/Preview Content/Fonts/` にあり、`UIAppFonts` に足さずに、ここで process の範囲に登録する。
/// フォルダ同期グループのリソースは `DEVELOPMENT_ASSET_PATHS` では Archive から外れないので、Release の構成の
/// `EXCLUDED_SOURCE_FILE_NAMES`（`Configs/Release.xcconfig`）で名前で外す。書体を足したら、ここと除外の名前の両方に足す。
/// 出荷するアプリではファイルが無いので何もしない。
///
/// TestFlight の確認用のブランチ（`testflight/theme-trial`）では、デバッグ用のテーマの切り替え（`DebugTheme`）のために
/// Release のビルドにも書体を入れ、ウィジェットからも登録する。そのため、このファイルをアプリだけの `OshiCon/` から `Shared/` に移した。
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

    /// 書体のファイルがあるバンドル。書体はアプリのターゲットのリソースなので、Widget Extension ではアプリのバンドル
    /// （`OshiCon.app/PlugIns/OshiConWidgetExtension.appex` の 2 つ上）から読む。
    static var fontBundle: Bundle {
        let main = Bundle.main
        guard main.bundleURL.pathExtension == "appex" else {
            return main
        }
        return Bundle(url: main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()) ?? main
    }

    private static let registration: Void = {
        for url in fontURLs(in: fontBundle) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
