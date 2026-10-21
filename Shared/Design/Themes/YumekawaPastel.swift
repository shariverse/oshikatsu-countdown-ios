//
//  YumekawaPastel.swift
//  OshiCon
//

import SwiftUI

extension AppTheme {
    /// テーマ案 1「ゆめかわパステル」。薄いピンク・ラベンダー・水色の地、丸い角、星やハートの小さな装飾。
    /// ダークは夜空のような深いラベンダーの地に、淡い色の装飾を置く。日本語の本文は丸い書体の Kiwi Maru。
    nonisolated static let yumekawaPastel = Self(
        id: "yumekawaPastel",
        displayName: "ゆめかわパステル",
        palette: Palette(
            background: AdaptiveColor(light: 0xFFF5FA, dark: 0x1C1726),
            surface: AdaptiveColor(light: 0xFFFFFF, dark: 0x272033),
            surfaceContainer: AdaptiveColor(light: 0xF7EEF8, dark: 0x221C2D),
            surfaceContainerHigh: AdaptiveColor(light: 0xEBDDF0, dark: 0x3B3150),
            onSurface: AdaptiveColor(light: 0x3E2D4C, dark: 0xF4EAF7),
            onSurfaceVariant: AdaptiveColor(light: 0x66557A, dark: 0xD5C6DE),
            outlineVariant: AdaptiveColor(light: 0xE3D0EC, dark: 0x55486B),
            brand: AdaptiveColor(light: 0xB23D78, dark: 0xFFB5D8),
            onBrand: AdaptiveColor(light: 0xFFFFFF, dark: 0x5A1A3D),
            brandContainer: AdaptiveColor(light: 0xFADCEC, dark: 0x6B3868),
            onBrandContainer: AdaptiveColor(light: 0x3E2D4C, dark: 0xFFDDF0),
            destructive: AdaptiveColor(light: 0xB3261E, dark: 0xF2B8B5)
        ),
        // 地が色付き（ピンク〜水色）なので、ライトの推し色の文字を少し黒に寄せて 4.5:1 を保つ
        oshiText: OshiTextAdjustment(
            lightTextDarkenFraction: 0.08,
            darkTextLightenFraction: 0.45,
            surfaceContainerTextDarkenFraction: 0.1,
            containerLightFraction: 0.18,
            containerDarkFraction: 0.35
        ),
        shape: CornerRadii(heroCard: 36, section: 28, detailCard: 36, tag: 12),
        typography: Typography(
            // Kiwi Maru は Regular と Medium を置く（Bold は Medium に寄せる。合成の太字にしない）
            textFaces: TextFaces(regular: "KiwiMaru-Regular", medium: "KiwiMaru-Medium", bold: "KiwiMaru-Medium"),
            numeralFamily: AppFont.numeralFamily,
            numeralWeight: .semibold
        ),
        decoration: Decoration(
            screenBackground: .sparkles(
                gradient: [
                    AdaptiveColor(light: 0xFFF5FA, dark: 0x1C1726),
                    AdaptiveColor(light: 0xF8F2FF, dark: 0x1A1830),
                    AdaptiveColor(light: 0xF1F8FF, dark: 0x16192C)
                ],
                ornament: AdaptiveColor(light: 0xF5B8D6, dark: 0x7A5E9E)
            ),
            cardBorder: .outline(color: AdaptiveColor(light: 0xF6CFE4, dark: 0x5E4A7A), width: 2),
            headingOrnament: .symbol(name: "sparkle", color: AdaptiveColor(light: 0xC48ADB, dark: 0xD9B8F0)),
            numeralEffect: .none,
            photoPlaceholder: .hearts
        )
    )
}
