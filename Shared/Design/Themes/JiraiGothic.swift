//
//  JiraiGothic.swift
//  OshiCon
//

import SwiftUI

extension AppTheme {
    /// 「地雷系・ゴシック」（Discussion #80 のテーマ案 4 から採用した、出荷するテーマ）。黒 × ピンク、ダークが主役。十字とハートの小さな装飾と、カードの二重の線。
    /// ライトも黒 × ピンクで、薄いピンクの地に黒の文字・黒の縁取り。日本語の本文は装飾的な明朝の Kaisei Decol。
    nonisolated static let jiraiGothic = Self(
        id: "jiraiGothic",
        displayName: "地雷系・ゴシック",
        palette: Palette(
            background: AdaptiveColor(light: 0xFFF0F5, dark: 0x120D12),
            surface: AdaptiveColor(light: 0xFFFFFF, dark: 0x1E141C),
            surfaceContainer: AdaptiveColor(light: 0xFBE4EE, dark: 0x180F16),
            surfaceContainerHigh: AdaptiveColor(light: 0xF0C9DA, dark: 0x3A2533),
            onSurface: AdaptiveColor(light: 0x1A0F16, dark: 0xF6E6EE),
            onSurfaceVariant: AdaptiveColor(light: 0x5A3A4C, dark: 0xD6B9C8),
            outlineVariant: AdaptiveColor(light: 0xE8B9CF, dark: 0x5C3A4E),
            brand: AdaptiveColor(light: 0xC2185B, dark: 0xFF7EB3),
            onBrand: AdaptiveColor(light: 0xFFFFFF, dark: 0x3A0A20),
            // 選択中の印の地。ホームの絞り込みの札は本文の色（onSurface）で書くので、ライトは淡いピンクにする
            brandContainer: AdaptiveColor(light: 0xF8C8DC, dark: 0x6E1E45),
            onBrandContainer: AdaptiveColor(light: 0x1A0F16, dark: 0xFFD9E8),
            destructive: AdaptiveColor(light: 0xB3261E, dark: 0xF2B8B5)
        ),
        // ライトの地が薄いピンクなので推し色の文字を少し黒に寄せる。入力欄の地（濃いめのピンク）の上はもう少し寄せる
        oshiText: OshiTextAdjustment(
            lightTextDarkenFraction: 0.08,
            darkTextLightenFraction: 0.45,
            surfaceContainerTextDarkenFraction: 0.12,
            containerLightFraction: 0.18,
            containerDarkFraction: 0.35
        ),
        shape: CornerRadii(heroCard: 16, section: 12, detailCard: 20, tag: 4),
        typography: Typography(
            // Kaisei Decol は Regular と Bold を置く（Medium は Regular に寄せる。合成の太字にしない）
            textFaces: TextFaces(regular: "KaiseiDecol-Regular", medium: "KaiseiDecol-Regular", bold: "KaiseiDecol-Bold"),
            numeralFamily: AppFont.numeralFamily,
            numeralWeight: .heavy
        ),
        decoration: Decoration(
            screenBackground: .crossesAndHearts(ornament: AdaptiveColor(light: 0xF2B6CF, dark: 0x4A2A3C)),
            cardBorder: .doubleLine(color: AdaptiveColor(light: 0x1A0F16, dark: 0xFF7EB3)),
            headingOrnament: .symbol(name: "heart.fill", color: AdaptiveColor(light: 0xC2185B, dark: 0xFF7EB3)),
            photoPlaceholder: .crosses
        )
    )
}
