//
//  AppFont.swift
//  OshiCon
//

import SwiftUI

/// 書体の共通の決まり。数字は Outfit、日本語の本文はテーマの書体（どちらも同梱。SIL OFL 1.1）。
/// 画面とウィジェットは、出荷するテーマの書体を `@Environment(\.appTheme)` の `typography` から引く。
/// ほかの言語の本文はシステムの書体にする（テーマの日本語の書体には中国語・韓国語・タイ語などの字形が無いため）。
/// どちらもダイナミックタイプの文字の大きさに合わせて大きさが変わる。
nonisolated enum AppFont {
    /// Outfit の family 名。可変フォントで、既定のインスタンスは Thin なので、必ず太さを付けて使う。
    static let numeralFamily = "Outfit"

    /// 本文の書体の PostScript 名。
    enum TextFace: String, CaseIterable {
        case regular = "ZenKakuGothicNew-Regular"
        case medium = "ZenKakuGothicNew-Medium"
        case bold = "ZenKakuGothicNew-Bold"
    }

    /// 本文にテーマの書体（同梱）を使うか。日本語のときだけ使う。
    static func usesBundledTextFace(locale: Locale) -> Bool {
        locale.isJapanese
    }

    static func face(for weight: Font.Weight) -> TextFace {
        switch weight {
        case .ultraLight, .thin, .light, .regular:
            .regular
        case .medium:
            .medium
        default:
            .bold
        }
    }

    /// ダイナミックタイプが標準（Large）のときの、テキストスタイルの大きさ（iOS の既定と同じ）。
    static func defaultSize(of style: Font.TextStyle) -> CGFloat {
        defaultSizes[style] ?? 17
    }

    private static let defaultSizes: [Font.TextStyle: CGFloat] = [
        .largeTitle: 34,
        .title: 28,
        .title2: 22,
        .title3: 20,
        .headline: 17,
        .body: 17,
        .callout: 16,
        .subheadline: 15,
        .footnote: 13,
        .caption: 12,
        .caption2: 11
    ]
}
