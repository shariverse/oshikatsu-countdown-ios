//
//  KoreanMinimal.swift
//  OshiCon
//

import SwiftUI

extension AppTheme {
    /// テーマ案 3「韓国風ミニマル」。くすみカラー（ベージュ・グレージュ・くすみピンク）の地、細い線と細めの数字。
    /// 模様は置かず、地の色と細い線だけで余白を広く見せる。日本語の本文は Zen Kaku Gothic New を 1 段ずつ細くして使う。
    nonisolated static let koreanMinimal = Self(
        id: "koreanMinimal",
        displayName: "韓国風ミニマル",
        palette: Palette(
            background: AdaptiveColor(light: 0xF6F1EC, dark: 0x1A1817),
            surface: AdaptiveColor(light: 0xFDFBF8, dark: 0x24211F),
            surfaceContainer: AdaptiveColor(light: 0xEFE8E1, dark: 0x1F1C1A),
            surfaceContainerHigh: AdaptiveColor(light: 0xE2D9D0, dark: 0x3A3532),
            onSurface: AdaptiveColor(light: 0x2F2A27, dark: 0xEDE6E0),
            onSurfaceVariant: AdaptiveColor(light: 0x5E5650, dark: 0xC9BFB7),
            outlineVariant: AdaptiveColor(light: 0xD8CEC5, dark: 0x4A443F),
            brand: AdaptiveColor(light: 0xA0525F, dark: 0xE5B5BC),
            onBrand: AdaptiveColor(light: 0xFFFFFF, dark: 0x4A2128),
            brandContainer: AdaptiveColor(light: 0xF0DCDD, dark: 0x5E3F44),
            onBrandContainer: AdaptiveColor(light: 0x2F2A27, dark: 0xF8E1E4),
            destructive: AdaptiveColor(light: 0xA8322B, dark: 0xF2B8B5)
        ),
        // くすんだベージュの地なので、ライトの推し色の文字を黒に寄せて 4.5:1 を保つ（入力欄の地の上はもう少し寄せる）
        oshiText: OshiTextAdjustment(
            lightTextDarkenFraction: 0.1,
            darkTextLightenFraction: 0.45,
            surfaceContainerTextDarkenFraction: 0.14,
            containerLightFraction: 0.18,
            containerDarkFraction: 0.35
        ),
        shape: CornerRadii(heroCard: 20, section: 16, detailCard: 24, tag: 6),
        typography: Typography(
            // 1 段ずつ細くする（regular は Preview 用の Light、medium は Regular、bold は Medium）
            textFaces: TextFaces(
                regular: "ZenKakuGothicNew-Light",
                medium: "ZenKakuGothicNew-Regular",
                bold: "ZenKakuGothicNew-Medium"
            ),
            numeralFamily: AppFont.numeralFamily,
            numeralWeight: .light
        ),
        decoration: Decoration(
            screenBackground: .none,
            cardBorder: .outline(color: AdaptiveColor(light: 0xE2D9D0, dark: 0x3A3532), width: 1),
            headingOrnament: .trailingRule(color: AdaptiveColor(light: 0xD8CEC5, dark: 0x4A443F)),
            numeralEffect: .none,
            photoPlaceholder: .tonal
        )
    )
}
