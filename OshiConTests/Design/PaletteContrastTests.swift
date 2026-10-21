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

    @Test("推し色の文字は、画面の地とカードの地に 4.5:1 以上（すべてのテーマ・ライトとダーク）", arguments: AppTheme.all, [false, true])
    func oshiTextOnGrounds(theme: AppTheme, isDark: Bool) {
        for color in OshiColor.allCases {
            let text = color.text(in: theme).resolved(isDark: isDark)
            for ground in [theme.palette.background, theme.palette.surface] {
                #expect(text.contrastRatio(with: ground.resolved(isDark: isDark)) >= 4.5, "\(color)")
            }
        }
    }

    @Test("推し色の文字は、ダークの入力欄の地にも 4.5:1 以上（すべてのテーマ）", arguments: AppTheme.all)
    func oshiTextOnDarkSurfaceContainer(theme: AppTheme) {
        for color in OshiColor.allCases {
            #expect(color.text(in: theme).dark.contrastRatio(with: theme.palette.surfaceContainer.dark) >= 4.5, "\(color)")
        }
    }

    @Test("推しカウントの地（surfaceContainer）の上の推し色の文字は 4.5:1 以上（すべてのテーマ・ライトとダーク）", arguments: AppTheme.all, [false, true])
    func oshiTextOnSurfaceContainer(theme: AppTheme, isDark: Bool) {
        let ground = theme.palette.surfaceContainer.resolved(isDark: isDark)
        for color in OshiColor.allCases {
            #expect(color.textOnSurfaceContainer(in: theme).resolved(isDark: isDark).contrastRatio(with: ground) >= 4.5, "\(color)")
        }
    }

    @Test("本文と補助テキストは地に 4.5:1 以上。アクセントの塗りに乗る文字も（すべてのテーマ）", arguments: AppTheme.all, [false, true])
    func textOnGrounds(theme: AppTheme, isDark: Bool) {
        let palette = theme.palette
        for ground in [palette.background, palette.surface, palette.surfaceContainer] {
            #expect(palette.onSurface.resolved(isDark: isDark).contrastRatio(with: ground.resolved(isDark: isDark)) >= 4.5)
            #expect(palette.onSurfaceVariant.resolved(isDark: isDark).contrastRatio(with: ground.resolved(isDark: isDark)) >= 4.5)
        }
        #expect(palette.onBrand.resolved(isDark: isDark).contrastRatio(with: palette.brand.resolved(isDark: isDark)) >= 4.5)
        let onContainer = palette.onBrandContainer.resolved(isDark: isDark)
        #expect(onContainer.contrastRatio(with: palette.brandContainer.resolved(isDark: isDark)) >= 4.5)
    }

    @Test("見出しなどの本文は、画面の地の模様（グラデーション・模様の色）の上でも 4.5:1 以上（すべてのテーマ）", arguments: AppTheme.all, [false, true])
    func textOnScreenDecoration(theme: AppTheme, isDark: Bool) {
        let palette = theme.palette
        for ground in theme.decoration.screenBackground.textGrounds(background: palette.background) {
            let resolved = ground.resolved(isDark: isDark)
            #expect(palette.onSurface.resolved(isDark: isDark).contrastRatio(with: resolved) >= 4.5)
            #expect(palette.onSurfaceVariant.resolved(isDark: isDark).contrastRatio(with: resolved) >= 4.5)
        }
    }

    @Test("推し色の文字は、画面の地のグラデーションの上でも 4.5:1 以上（すべてのテーマ・ライトとダーク）", arguments: AppTheme.all, [false, true])
    func oshiTextOnScreenGradient(theme: AppTheme, isDark: Bool) {
        let grounds = theme.decoration.screenBackground.grounds(background: theme.palette.background)
        for color in OshiColor.allCases {
            let text = color.text(in: theme).resolved(isDark: isDark)
            for ground in grounds {
                #expect(text.contrastRatio(with: ground.resolved(isDark: isDark)) >= 4.5, "\(color)")
            }
        }
    }

    @Test("アクセント（brand）を文字に使ったとき、画面の地とカードの地に 4.5:1 以上（すべてのテーマ・ライトとダーク）", arguments: AppTheme.all, [false, true])
    func brandTextOnGrounds(theme: AppTheme, isDark: Bool) {
        // brand は `.tint` でボタンや値の文字にもなる
        let palette = theme.palette
        let brand = palette.brand.resolved(isDark: isDark)
        for ground in [palette.background, palette.surface] + theme.decoration.screenBackground.grounds(background: palette.background) {
            #expect(brand.contrastRatio(with: ground.resolved(isDark: isDark)) >= 4.5)
        }
    }

    @Test("選択中の印の地（brandContainer）に乗せた本文は 4.5:1 以上（すべてのテーマ・ライトとダーク）", arguments: AppTheme.all, [false, true])
    func textOnBrandContainer(theme: AppTheme, isDark: Bool) {
        // ホームの絞り込みの札は、選択中でも本文の色（onSurface）で書く
        let palette = theme.palette
        #expect(palette.onSurface.resolved(isDark: isDark).contrastRatio(with: palette.brandContainer.resolved(isDark: isDark)) >= 4.5)
    }

    @Test("推し色を薄く敷いた地に乗せた本文は 4.5:1 以上（すべてのテーマ）", arguments: AppTheme.all, [false, true])
    func textOnOshiContainer(theme: AppTheme, isDark: Bool) {
        let text = theme.palette.onSurface.resolved(isDark: isDark)
        for color in OshiColor.allCases {
            #expect(text.contrastRatio(with: color.container(in: theme).resolved(isDark: isDark)) >= 4.5, "\(color)")
        }
    }

    @Test("既定のテーマのライトの入力欄の地は、推し色の文字が 4.5:1 を保てない色がある（推し色の文字を置かない）")
    func oshiTextIsNotForLightSurfaceContainer() {
        let ground = AppTheme.standard.palette.surfaceContainer.light
        let ratios = OshiColor.allCases.map { $0.text(in: .standard).light.contrastRatio(with: ground) }
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
        #expect(Set(OshiColor.allCases.map { $0.label(locale: DomainFixtures.japanese) }).count == 12)
        #expect(OshiColor.pink.label(locale: DomainFixtures.japanese) == "ピンク")
    }
}
