//
//  AppFont.swift
//  OshiCon
//

import SwiftUI

/// アプリの書体。数字は Outfit、本文は日本語のときだけ Zen Kaku Gothic New（どちらも同梱。SIL OFL 1.1）。
/// ほかの言語の本文はシステムの書体にする（Zen Kaku Gothic New には中国語・韓国語・タイ語などの字形が無いため）。
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

    // MARK: - 数字（Outfit）。桁の幅をそろえ、秒が進んでも横に揺れない。値は既定のテーマ（`AppTheme.standard`）のもの

    /// 詳細の残り日数。
    static let countdownHero = standard.countdownHero
    /// ホームの先頭の残り日数。
    static let countdownLarge = standard.countdownLarge
    /// 詳細の時・分・秒。
    static let countdownClock = standard.countdownClock
    /// 一覧の行の残り日数。
    static let countdownSmall = standard.countdownSmall
    /// 先頭のカードの日付（`10.18 SUN`）。
    static let dateBadge = standard.dateBadge

    /// Outfit の数字。`size` はダイナミックタイプが標準のときの大きさ。
    static func numeral(size: CGFloat, weight: Font.Weight = .bold, relativeTo style: Font.TextStyle) -> Font {
        standard.numeral(size: size, weight: weight, relativeTo: style)
    }

    // MARK: - 本文（日本語は Zen Kaku Gothic New、ほかの言語はシステムの書体）

    /// 本文の書体。日本語では太さを regular・medium・bold の 3 つに丸める。
    static func text(_ style: Font.TextStyle, weight: Font.Weight = .regular, locale: Locale = .app) -> Font {
        standard.text(style, weight: weight, locale: locale)
    }

    private static var standard: AppTheme.Typography {
        AppTheme.standard.typography
    }

    /// 本文に同梱の書体（Zen Kaku Gothic New）を使うか。日本語のときだけ使う。
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
