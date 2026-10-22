//
//  OshiColor+Appearance.swift
//  OshiCon
//

import SwiftUI

extension OshiColor {
    /// 塗りの色。どの色も、上に置く白い文字に対して 4.5:1 以上になる濃さ（Android 版と同じ値）。
    nonisolated var rgb: RGBColor {
        switch self {
        case .pink:
            RGBColor(hex: 0xC8326A)
        case .red:
            RGBColor(hex: 0xD0352B)
        case .orange:
            RGBColor(hex: 0xB45A0E)
        case .yellow:
            RGBColor(hex: 0x8A6D00)
        case .green:
            RGBColor(hex: 0x1A7A50)
        case .mint:
            RGBColor(hex: 0x0E7C86)
        case .blue:
            RGBColor(hex: 0x2F6FD6)
        case .navy:
            RGBColor(hex: 0x3B4BB8)
        case .purple:
            RGBColor(hex: 0x7A4BD0)
        case .lavender:
            RGBColor(hex: 0xA23FB0)
        case .brown:
            RGBColor(hex: 0x6B5B4B)
        case .black:
            RGBColor(hex: 0x3A3842)
        }
    }

    /// 色の名前（読み上げと推し色を選ぶところ）。
    nonisolated var label: String {
        label(locale: .app)
    }

    nonisolated func label(locale: Locale) -> String {
        var resource = labelResource
        resource.locale = locale
        return String(localized: resource)
    }

    nonisolated private var labelResource: LocalizedStringResource {
        switch self {
        case .pink:
            "ピンク"
        case .red:
            "レッド"
        case .orange:
            "オレンジ"
        case .yellow:
            "イエロー"
        case .green:
            "グリーン"
        case .mint:
            "ミント"
        case .blue:
            "ブルー"
        case .navy:
            "ネイビー"
        case .purple:
            "パープル"
        case .lavender:
            "ラベンダー"
        case .brown:
            "ブラウン"
        case .black:
            "ブラック"
        }
    }

    /// 推し色を地（画面の地・カード）の上の文字や細い線に使うときの色。ダークでは暗い推し色が沈まないよう白に寄せる。
    /// ライトで黒に寄せる割合・ダークで白に寄せる割合はテーマが持つ。surfaceContainer の上の文字は `textOnSurfaceContainer(in:)` を使う。
    nonisolated func text(in theme: AppTheme) -> AdaptiveColor {
        AdaptiveColor(
            light: rgb.mixed(with: .black, fraction: theme.oshiText.lightTextDarkenFraction),
            dark: rgb.mixed(with: .white, fraction: theme.oshiText.darkTextLightenFraction)
        )
    }

    /// 推し色を surfaceContainer（入力欄・推しカウントウィジェットの地）の上の文字に使うときの色。
    /// ライトでは少し黒に寄せて 4.5:1 を保つ（割合はテーマが持つ）。ダークは `text(in:)` と同じ。
    nonisolated func textOnSurfaceContainer(in theme: AppTheme) -> AdaptiveColor {
        AdaptiveColor(
            light: rgb.mixed(with: .black, fraction: theme.oshiText.surfaceContainerTextDarkenFraction),
            dark: text(in: theme).dark
        )
    }

    /// 推し色を薄く敷いた地（選択中の印など）。文字はテーマの `onSurface`。テーマのカードの地に、テーマが持つ割合だけ推し色を混ぜる。
    nonisolated func container(in theme: AppTheme) -> AdaptiveColor {
        AdaptiveColor(
            light: theme.palette.surface.light.mixed(with: rgb, fraction: theme.oshiText.containerLightFraction),
            dark: theme.palette.surface.dark.mixed(with: rgb, fraction: theme.oshiText.containerDarkFraction)
        )
    }

    /// 塗りの色。外観で変わらない。
    var fill: Color {
        rgb.color
    }

    /// 塗りの上の文字。
    var onFill: Color {
        .white
    }
}
