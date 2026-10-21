//
//  ThemeDecorations.swift
//  OshiCon
//

import SwiftUI

// テーマの装飾の差し込み口。どれも `@Environment(\.appTheme)` の装飾を描き、標準のテーマ（装飾が「無し」）では何も変えない。
// 装飾は読み上げ・押せる範囲・並びを変えず（`accessibilityHidden(true)`・`allowsHitTesting(false)`）、文字の上に重ねない。

/// 画面の地。テーマの地の色に、テーマの模様を重ねる（標準のテーマは色だけ）。
struct ThemeScreenBackground: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        switch theme.decoration.screenBackground {
        case .none:
            theme.palette.background.color
        case let .sparkles(gradient, ornament):
            SparkleBackground(gradient: gradient, ornament: ornament)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        case let .crossesAndHearts(ornament):
            CrossesAndHeartsBackground(ground: theme.palette.background, ornament: ornament)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        case let .stage(gradient, beam):
            StageBackground(gradient: gradient, beam: beam)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
    }
}

/// 写真が無いときに写真の場所を埋める模様。標準のテーマは推し色の斜めの縞。
struct ThemePhotoPlaceholder: View {
    let color: OshiColor

    @Environment(\.appTheme) private var theme

    var body: some View {
        switch theme.decoration.photoPlaceholder {
        case .stripes:
            StripedBackground(color: color)
        case .hearts:
            HeartPatternBackground(color: color)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        case .tonal:
            TonalBackground(color: color)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        case .gingham:
            GinghamBackground(color: color)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        case .crosses:
            CrossPatternBackground(color: color)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        case .penlights:
            PenlightBokehBackground(color: color)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
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

    /// 残り日数の数字の効果（光・グラデーション）。`color` はその予定の推し色、`ground` は数字が乗る地。
    func themeNumeralEffect(_ color: OshiColor, on ground: AppTheme.NumeralGround = .ground) -> some View {
        modifier(ThemeNumeralEffectModifier(color: color, ground: ground))
    }
}

private struct ThemeCardBorderModifier<CardShape: InsettableShape>: ViewModifier {
    let shape: CardShape

    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        switch theme.decoration.cardBorder {
        case .none:
            content
        case let .outline(color, width):
            content.overlay {
                shape.strokeBorder(color.color, lineWidth: width)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        case let .lace(color):
            content.overlay {
                LaceBorder(shape: shape, color: color)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        case let .doubleLine(color):
            content.overlay {
                DoubleLineBorder(shape: shape, color: color)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        case let .neon(color):
            content.overlay {
                NeonBorder(shape: shape, color: color)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct ThemeHeadingOrnamentModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        switch theme.decoration.headingOrnament {
        case .none:
            content
        case let .symbol(name, color):
            // 飾りは見出しの文字の前に並べ、文字には重ねない。大きさは見出しに合わせてダイナミックタイプで変わる
            // 2 行になっても 1 行目にそろえる。大きな文字では見出しの幅を削りすぎないよう、飾りの大きさに上限を付ける
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: name)
                    .font(.headline)
                    .imageScale(.small)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .foregroundStyle(color.color)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                content
            }
        case let .trailingRule(color):
            // 線は見出しの文字の後ろに並べ、文字を押しのけない（文字が先に幅を取り、線は残りの幅だけ）
            HStack(spacing: 12) {
                content
                    .layoutPriority(1)
                ThinRule(color: color)
            }
        case let .ribbon(color):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                RibbonOrnament(color: color)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                content
            }
        }
    }
}

private struct ThemeNumeralEffectModifier: ViewModifier {
    let color: OshiColor
    let ground: AppTheme.NumeralGround

    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        switch theme.decoration.numeralEffect {
        case .none:
            content
        case .glow:
            // 光は数字の下に敷く影で描き、数字の色・大きさ・並びは変えない
            if let glow = theme.decoration.numeralEffect.glow(for: color, on: ground) {
                content.shadow(color: glow.color.color.opacity(glow.opacity), radius: glow.radius)
            } else {
                content
            }
        }
    }
}
