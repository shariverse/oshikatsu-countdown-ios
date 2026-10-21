//
//  IdolPenlight.swift
//  OshiCon
//

import SwiftUI

extension AppTheme {
    /// テーマ案 5「アイドル・ペンライト」。推し色を大きく光らせる、ネオンの数字、ライブ会場の高揚感。
    /// ダークは開演前の会場のような深い紫の地に照明の光の筋を差し、ライトは明るいステージの白い地にする。
    /// 数字の光は推し色から作り（推し色は置き換えない）、日本語の本文はポップな書体の Mochiy Pop One。
    nonisolated static let idolPenlight = Self(
        id: "idolPenlight",
        displayName: "アイドル・ペンライト",
        palette: Palette(
            background: AdaptiveColor(light: 0xFBF7FF, dark: 0x0E0B1A),
            surface: AdaptiveColor(light: 0xFFFFFF, dark: 0x1A1530),
            surfaceContainer: AdaptiveColor(light: 0xF2ECFA, dark: 0x151126),
            surfaceContainerHigh: AdaptiveColor(light: 0xE2D9F0, dark: 0x2E2650),
            onSurface: AdaptiveColor(light: 0x1E1530, dark: 0xF5F0FF),
            onSurfaceVariant: AdaptiveColor(light: 0x51466A, dark: 0xCFC6E8),
            outlineVariant: AdaptiveColor(light: 0xD5CBE6, dark: 0x3D3466),
            brand: AdaptiveColor(light: 0x9B2FC8, dark: 0xFF8AD0),
            onBrand: AdaptiveColor(light: 0xFFFFFF, dark: 0x3A0026),
            brandContainer: AdaptiveColor(light: 0xEBD9F7, dark: 0x5A2D7A),
            onBrandContainer: AdaptiveColor(light: 0x1E1530, dark: 0xFFE3F4),
            destructive: AdaptiveColor(light: 0xB3261E, dark: 0xF2B8B5)
        ),
        // 地が淡いラベンダーとピンクなので、ライトの推し色の文字を少し黒に寄せて 4.5:1 を保つ
        oshiText: OshiTextAdjustment(
            lightTextDarkenFraction: 0.08,
            darkTextLightenFraction: 0.45,
            surfaceContainerTextDarkenFraction: 0.12,
            containerLightFraction: 0.18,
            containerDarkFraction: 0.35
        ),
        shape: CornerRadii(heroCard: 32, section: 24, detailCard: 32, tag: 12),
        typography: Typography(
            // Mochiy Pop One は太さが 1 つだけなので、3 つの太さをすべてこれに寄せる（合成の太字にしない）
            textFaces: TextFaces(regular: "MochiyPopOne-Regular", medium: "MochiyPopOne-Regular", bold: "MochiyPopOne-Regular"),
            numeralFamily: AppFont.numeralFamily,
            numeralWeight: .black
        ),
        decoration: Decoration(
            screenBackground: .stage(
                gradient: [
                    AdaptiveColor(light: 0xFBF7FF, dark: 0x0E0B1A),
                    AdaptiveColor(light: 0xF6F0FF, dark: 0x130E26),
                    AdaptiveColor(light: 0xFDF3FA, dark: 0x1A0D24)
                ],
                beam: AdaptiveColor(light: 0xE9D5FF, dark: 0x6B4BB8)
            ),
            cardBorder: .neon(color: AdaptiveColor(light: 0xC77DFF, dark: 0xB57BFF)),
            headingOrnament: .symbol(name: "music.note", color: AdaptiveColor(light: 0x9B2FC8, dark: 0xFF8AD0)),
            numeralEffect: .glow,
            photoPlaceholder: .penlights
        )
    )
}
