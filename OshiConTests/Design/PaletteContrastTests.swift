//
//  PaletteContrastTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct PaletteContrastTests {
    @Test("推し色の塗りに乗せた白い文字は 4.5:1 以上", arguments: OshiColor.allCases)
    func whiteTextOnOshiColor(color: OshiColor) {
        #expect(RGBColor.white.contrastRatio(with: color.rgb) >= 4.5)
    }

    @Test("推し色の文字は、ライトの画面の地とカードの地に 4.5:1 以上", arguments: OshiColor.allCases)
    func oshiTextOnLightGrounds(color: OshiColor) {
        for ground in [AppPalette.background, AppPalette.surface] {
            #expect(color.text.light.contrastRatio(with: ground.light) >= 4.5)
        }
    }

    @Test("推し色の文字は、ダークの画面の地・カード・入力欄の地に 4.5:1 以上", arguments: OshiColor.allCases)
    func oshiTextOnDarkGrounds(color: OshiColor) {
        for ground in [AppPalette.background, AppPalette.surface, AppPalette.surfaceContainer] {
            #expect(color.text.dark.contrastRatio(with: ground.dark) >= 4.5)
        }
    }

    @Test("本文と補助テキストは地に 4.5:1 以上。アクセントの塗りに乗る文字も", arguments: [false, true])
    func textOnGrounds(isDark: Bool) {
        for ground in [AppPalette.background, AppPalette.surface, AppPalette.surfaceContainer] {
            #expect(AppPalette.onSurface.resolved(isDark: isDark).contrastRatio(with: ground.resolved(isDark: isDark)) >= 4.5)
            #expect(AppPalette.onSurfaceVariant.resolved(isDark: isDark).contrastRatio(with: ground.resolved(isDark: isDark)) >= 4.5)
        }
        #expect(AppPalette.onBrand.resolved(isDark: isDark).contrastRatio(with: AppPalette.brand.resolved(isDark: isDark)) >= 4.5)
        let onContainer = AppPalette.onBrandContainer.resolved(isDark: isDark)
        #expect(onContainer.contrastRatio(with: AppPalette.brandContainer.resolved(isDark: isDark)) >= 4.5)
    }

    @Test("推し色を薄く敷いた地に乗せた本文は 4.5:1 以上")
    func textOnOshiContainer() {
        for color in OshiColor.allCases {
            #expect(AppPalette.onSurface.light.contrastRatio(with: color.container.light) >= 4.5)
            #expect(AppPalette.onSurface.dark.contrastRatio(with: color.container.dark) >= 4.5)
        }
    }

    @Test("ライトの入力欄の地は、推し色の文字が 4.5:1 を保てない色がある（推し色の文字を置かない）")
    func oshiTextIsNotForLightSurfaceContainer() {
        let ratios = OshiColor.allCases.map { $0.text.light.contrastRatio(with: AppPalette.surfaceContainer.light) }
        #expect(ratios.contains { $0 < 4.5 })
    }

    @Test("コントラスト比の計算は WCAG の値と合う")
    func contrastRatio() {
        #expect(abs(RGBColor.white.contrastRatio(with: .black) - 21) < 0.001)
        #expect(RGBColor.white.contrastRatio(with: .white) == 1)
        #expect(RGBColor(hex: 0x777777).contrastRatio(with: .white) > 4.47)
        #expect(RGBColor(hex: 0x777777).contrastRatio(with: .white) < 4.49)
    }

    @Test("色を混ぜる")
    func mixed() {
        let gray = RGBColor.black.mixed(with: .white, fraction: 0.5)
        #expect(gray == RGBColor(red: 0.5, green: 0.5, blue: 0.5))
        #expect(RGBColor(hex: 0xC8326A).mixed(with: .white, fraction: 0) == RGBColor(hex: 0xC8326A))
    }

    @Test("推し色は 12 色で名前がそろう")
    func labels() {
        #expect(Set(OshiColor.allCases.map(\.label)).count == 12)
        #expect(OshiColor.pink.label == "ピンク")
    }
}
