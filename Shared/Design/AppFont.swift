//
//  AppFont.swift
//  OshiCon
//

import SwiftUI

/// アプリの書体。数字は Outfit、本文は Zen Kaku Gothic New（どちらも同梱。SIL OFL 1.1）。
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

    // MARK: - 数字（Outfit）。桁の幅をそろえ、秒が進んでも横に揺れない

    /// 詳細の残り日数。
    static let countdownHero = numeral(size: 88, relativeTo: .largeTitle)
    /// ホームの先頭の残り日数。
    static let countdownLarge = numeral(size: 68, relativeTo: .largeTitle)
    /// 詳細の時・分・秒。
    static let countdownClock = numeral(size: 32, relativeTo: .title)
    /// 一覧の行の残り日数。
    static let countdownSmall = numeral(size: 24, relativeTo: .title2)
    /// 先頭のカードの日付（`10.18 SUN`）。
    static let dateBadge = numeral(size: 18, relativeTo: .headline)

    /// Outfit の数字。`size` はダイナミックタイプが標準のときの大きさ。
    static func numeral(size: CGFloat, weight: Font.Weight = .bold, relativeTo style: Font.TextStyle) -> Font {
        .custom(numeralFamily, size: size, relativeTo: style)
            .weight(weight)
            .monospacedDigit()
    }

    // MARK: - 本文（Zen Kaku Gothic New）

    /// 本文の書体。太さは regular・medium・bold の 3 つに丸める。
    static func text(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .custom(face(for: weight).rawValue, size: defaultSize(of: style), relativeTo: style)
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
