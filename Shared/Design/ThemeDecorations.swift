//
//  ThemeDecorations.swift
//  OshiCon
//

import SwiftUI

// テーマの装飾の差し込み口。どれも `@Environment(\.appTheme)` の装飾を描き、既定のテーマ（装飾が「無し」）では何も変えない。
// 装飾は読み上げ・押せる範囲・並びを変えず（`accessibilityHidden(true)`・`allowsHitTesting(false)`）、文字の上に重ねない。

/// 画面の地。テーマの地の色に、テーマの模様を重ねる（既定のテーマは色だけ）。
struct ThemeScreenBackground: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        switch theme.decoration.screenBackground {
        case .none:
            theme.palette.background.color
        }
    }
}

/// 写真が無いときに写真の場所を埋める模様。既定のテーマは推し色の斜めの縞。
struct ThemePhotoPlaceholder: View {
    let color: OshiColor

    @Environment(\.appTheme) private var theme

    var body: some View {
        switch theme.decoration.photoPlaceholder {
        case .stripes:
            StripedBackground(color: color)
        }
    }
}

extension View {
    /// カード（先頭のカード・見出しつきのまとまり）の縁取り。`shape` はカードの形。
    func themeCardBorder(_ shape: some InsettableShape) -> some View {
        modifier(ThemeCardBorderModifier(shape: shape))
    }

    /// 見出しの飾り。
    func themeHeadingOrnament() -> some View {
        modifier(ThemeHeadingOrnamentModifier())
    }

    /// 残り日数の数字の効果（光・グラデーション）。`color` はその予定の推し色。
    func themeNumeralEffect(_ color: OshiColor) -> some View {
        modifier(ThemeNumeralEffectModifier(color: color))
    }
}

private struct ThemeCardBorderModifier<CardShape: InsettableShape>: ViewModifier {
    let shape: CardShape

    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        switch theme.decoration.cardBorder {
        case .none:
            content
        }
    }
}

private struct ThemeHeadingOrnamentModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        switch theme.decoration.headingOrnament {
        case .none:
            content
        }
    }
}

private struct ThemeNumeralEffectModifier: ViewModifier {
    let color: OshiColor

    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        switch theme.decoration.numeralEffect {
        case .none:
            content
        }
    }
}
