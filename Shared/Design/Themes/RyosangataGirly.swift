//
//  RyosangataGirly.swift
//  OshiCon
//

import SwiftUI

extension AppTheme {
    /// テーマ案 2「量産型ガーリー」。ピンク × 白、リボン・レース風の縁取り、丸ゴシックの見出し。
    /// ライトは白いカードを淡いピンクの地に置き、ダークは深いローズの地にする。日本語の本文は丸ゴシックの Zen Maru Gothic。
    nonisolated static let ryosangataGirly = Self(
        id: "ryosangataGirly",
        displayName: "量産型ガーリー",
        palette: Palette(
            background: AdaptiveColor(light: 0xFFF0F5, dark: 0x24141B),
            surface: AdaptiveColor(light: 0xFFFFFF, dark: 0x33202A),
            surfaceContainer: AdaptiveColor(light: 0xFCE6EE, dark: 0x2C1A23),
            surfaceContainerHigh: AdaptiveColor(light: 0xF5D3E0, dark: 0x4A3040),
            onSurface: AdaptiveColor(light: 0x4A2333, dark: 0xFCE8F0),
            onSurfaceVariant: AdaptiveColor(light: 0x7A4A5C, dark: 0xE2C2D0),
            outlineVariant: AdaptiveColor(light: 0xF2C4D5, dark: 0x6A4656),
            brand: AdaptiveColor(light: 0xC2306D, dark: 0xFFADCB),
            onBrand: AdaptiveColor(light: 0xFFFFFF, dark: 0x5C1131),
            brandContainer: AdaptiveColor(light: 0xFFD6E5, dark: 0x7A2E4E),
            onBrandContainer: AdaptiveColor(light: 0x4A2333, dark: 0xFFD9E6),
            destructive: AdaptiveColor(light: 0xB3261E, dark: 0xF2B8B5)
        ),
        // 地が淡いピンクなので、ライトの推し色の文字を少し黒に寄せて 4.5:1 を保つ
        oshiText: OshiTextAdjustment(
            lightTextDarkenFraction: 0.08,
            darkTextLightenFraction: 0.45,
            surfaceContainerTextDarkenFraction: 0.1,
            containerLightFraction: 0.18,
            containerDarkFraction: 0.35
        ),
        shape: CornerRadii(heroCard: 30, section: 24, detailCard: 30, tag: 14),
        typography: Typography(
            // Zen Maru Gothic は Regular と Bold を置く（Medium は Regular に寄せる。合成の太字にしない）
            textFaces: TextFaces(regular: "ZenMaruGothic-Regular", medium: "ZenMaruGothic-Regular", bold: "ZenMaruGothic-Bold"),
            numeralFamily: AppFont.numeralFamily,
            numeralWeight: .bold
        ),
        decoration: Decoration(
            screenBackground: .none,
            cardBorder: .lace(color: AdaptiveColor(light: 0xF7B6CE, dark: 0x8A4D68)),
            headingOrnament: .ribbon(color: AdaptiveColor(light: 0xE86A9A, dark: 0xFF9DC0)),
            numeralEffect: .none,
            photoPlaceholder: .gingham
        )
    )
}
