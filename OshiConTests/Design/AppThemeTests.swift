//
//  AppThemeTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftUI
import Testing

struct AppThemeTests {
    @Test("出荷するテーマの数字の書体は Outfit・テーマの太さ・桁の幅をそろえる")
    func shippingNumerals() {
        func outfit(_ size: CGFloat, _ style: Font.TextStyle, _ weight: Font.Weight = .heavy) -> Font {
            .custom("Outfit", size: size, relativeTo: style).weight(weight).monospacedDigit()
        }
        let typography = AppTheme.shipping.typography
        #expect(typography.countdownHero == outfit(88, .largeTitle))
        #expect(typography.countdownLarge == outfit(68, .largeTitle))
        #expect(typography.countdownClock == outfit(32, .title))
        #expect(typography.countdownSmall == outfit(24, .title2))
        #expect(typography.dateBadge == outfit(18, .headline))
        #expect(typography.numeral(size: 40, relativeTo: .title) == outfit(40, .title))
        #expect(typography.numeral(size: 40, weight: .medium, relativeTo: .title) == outfit(40, .title, .medium))
    }

    @Test(
        "出荷するテーマの本文の書体は、日本語ではテーマの書体（太さは 3 つに丸める）、ほかの言語はシステムの書体",
        arguments: [Font.Weight.light, .regular, .medium, .semibold, .bold, .heavy]
    )
    func shippingText(weight: Font.Weight) {
        let typography = AppTheme.shipping.typography
        let face = typography.textFaces.name(for: weight)
        for style in [Font.TextStyle.largeTitle, .title2, .headline, .body, .subheadline, .caption] {
            let japanese = typography.text(style, weight: weight, locale: DomainFixtures.japanese)
            #expect(japanese == .custom(face, size: AppFont.defaultSize(of: style), relativeTo: style))
            #expect(typography.text(style, weight: weight, locale: DomainFixtures.english) == .system(style, weight: weight))
        }
    }

    @Test("模様の無い画面の地で文字が乗るのは、地の色だけ")
    func textGroundsWithoutPattern() {
        let background = AdaptiveColor(light: 0xFFFFFF, dark: 0x000000)
        #expect(AppTheme.ScreenBackground.none.grounds(background: background) == [background])
        #expect(AppTheme.ScreenBackground.none.textGrounds(background: background) == [background])
    }

    @Test("地雷系・ゴシックは Kaisei Decol・太い数字・十字とハートの装飾で、推し色の値は変えない")
    func jiraiGothic() {
        let theme = AppTheme.jiraiGothic
        #expect(theme.typography.textFaces == AppTheme.TextFaces(
            regular: "KaiseiDecol-Regular",
            medium: "KaiseiDecol-Regular",
            bold: "KaiseiDecol-Bold"
        ))
        #expect(theme.typography.numeralFamily == AppFont.numeralFamily)
        #expect(theme.typography.numeralWeight == .heavy)
        #expect(theme.shape == AppTheme.CornerRadii(heroCard: 16, section: 12, detailCard: 20, tag: 4))
        #expect(theme.decoration.screenBackground == .crossesAndHearts(ornament: AdaptiveColor(light: 0xF2B6CF, dark: 0x4A2A3C)))
        #expect(theme.decoration.cardBorder == .doubleLine(color: AdaptiveColor(light: 0x1A0F16, dark: 0xFF7EB3)))
        #expect(theme.decoration.headingOrnament == .symbol(name: "heart.fill", color: theme.palette.brand))
        #expect(theme.decoration.photoPlaceholder == .crosses)
        for color in OshiColor.allCases {
            #expect(color.text(in: theme).light == color.rgb.mixed(with: .black, fraction: 0.08))
            #expect(color.text(in: theme).dark == color.rgb.mixed(with: .white, fraction: 0.45))
            #expect(color.textOnSurfaceContainer(in: theme).light == color.rgb.mixed(with: .black, fraction: 0.12))
        }
    }

    @Test("十字とハートの地の色は画面の地の色で、文字が乗るのはその色と、模様の色を不透明度の分だけ重ねた色")
    func textGroundsWithCrossesAndHearts() {
        let background = AdaptiveColor(light: 0xFFFFFF, dark: 0x000000)
        let ornament = AdaptiveColor(light: 0xFF0000, dark: 0x0000FF)
        let opacity = AppTheme.ScreenBackground.markOpacity
        let marks = AppTheme.ScreenBackground.crossesAndHearts(ornament: ornament)
        #expect(marks.grounds(background: background) == [background])
        let grounds = marks.textGrounds(background: background)
        #expect(grounds.count == 2)
        #expect(grounds[0] == background)
        #expect(grounds[1].light == background.light.mixed(with: ornament.light, fraction: opacity))
        #expect(grounds[1].dark == background.dark.mixed(with: ornament.dark, fraction: opacity))
    }

    @Test("出荷するテーマは地雷系・ゴシックで、Environment のテーマの既定も出荷するテーマ")
    func environmentDefault() {
        #expect(AppTheme.shipping == .jiraiGothic)
        #expect(EnvironmentValues().appTheme == .shipping)
    }

    // MARK: - テーマカラー（1 位の推しの推し色）

    @Test("推しがいなければ、出荷するテーマのまま")
    func shippingWithoutThemeColor() {
        #expect(AppTheme.shipping(themeColor: nil) == .shipping)
    }

    @Test("基準のピンクで染めても、配色と装飾は元のまま")
    func tintedWithReferenceKeepsColors() {
        let tinted = AppTheme.shipping(themeColor: AppTheme.themeColorReference)
        #expect(tinted.palette == AppTheme.shipping.palette)
        #expect(tinted.decoration == AppTheme.shipping.decoration)
    }

    @Test("染めても、削除の文字・推し色の文字の調整・角の丸み・書体・装飾の形は変えない", arguments: OshiColor.allCases)
    func tintedKeepsNonColorParts(color: OshiColor) {
        let base = AppTheme.shipping
        let tinted = AppTheme.shipping(themeColor: color)
        #expect(tinted.id == "jiraiGothic.\(color.rawValue)")
        #expect(tinted.palette.destructive == base.palette.destructive)
        #expect(tinted.oshiText == base.oshiText)
        #expect(tinted.shape == base.shape)
        #expect(tinted.typography == base.typography)
        #expect(tinted.decoration.photoPlaceholder == base.decoration.photoPlaceholder)
        guard case let .symbol(name, _) = tinted.decoration.headingOrnament else {
            Issue.record("見出しの飾りが SF Symbols でない")
            return
        }
        #expect(name == "heart.fill")
        // カードの地（ライト）は白のまま
        #expect(tinted.palette.surface.light == .white)
    }

    @Test("ネイビーで染めると、アクセント・地・装飾のピンクが青みに変わる")
    func tintedWithNavy() {
        let tinted = AppTheme.shipping(themeColor: .navy)
        let palette = tinted.palette
        for color in [palette.brand, palette.background, palette.brandContainer, palette.surfaceContainerHigh] {
            #expect(color.light.blue > color.light.red)
            #expect(color.dark.blue > color.dark.red)
        }
        guard case let .crossesAndHearts(ornament) = tinted.decoration.screenBackground,
              case let .doubleLine(border) = tinted.decoration.cardBorder else {
            Issue.record("装飾の形が変わった")
            return
        }
        #expect(ornament.light.blue > ornament.light.red)
        #expect(border.dark.blue > border.dark.red)
        // アクセントは推し色の文字と同じ濃さの役割（ライトはほぼ推し色、ダークは明るい推し色）
        #expect(palette.brand.light.contrastRatio(with: OshiColor.navy.rgb) < 1.5)
    }

    @Test("色の置き換え: 白・黒・灰色は変えず、基準の色はそのまま置き換え先の色になる")
    func retintedNeutralAndReference() {
        let reference = OshiColor.pink.rgb
        let navy = OshiColor.navy.rgb
        #expect(RGBColor.white.retinted(from: reference, to: navy) == .white)
        #expect(RGBColor.black.retinted(from: reference, to: navy) == .black)
        let gray = RGBColor(hex: 0x808080)
        #expect(gray.retinted(from: reference, to: navy) == gray)
        let replaced = reference.retinted(from: reference, to: navy)
        #expect(abs(replaced.red - navy.red) < 1e-9)
        #expect(abs(replaced.green - navy.green) < 1e-9)
        #expect(abs(replaced.blue - navy.blue) < 1e-9)
    }

    @Test("色の置き換え: 基準を薄めた色は、置き換え先を同じだけ薄めた色に近く、0〜1 に収まる")
    func retintedTint() {
        let reference = OshiColor.pink.rgb
        for color in OshiColor.allCases.map(\.rgb) {
            let lightPink = RGBColor.white.mixed(with: reference, fraction: 0.2)
            let replaced = lightPink.retinted(from: reference, to: color)
            let expected = RGBColor.white.mixed(with: color, fraction: 0.2)
            #expect(abs(replaced.red - expected.red) < 0.02)
            #expect(abs(replaced.green - expected.green) < 0.02)
            #expect(abs(replaced.blue - expected.blue) < 0.02)
            for channel in [replaced.red, replaced.green, replaced.blue] {
                #expect((0...1).contains(channel))
            }
        }
    }

    @Test("色の置き換え: 基準が灰色なら、含む割合を決められないので変えない")
    func retintedGrayReference() {
        let color = RGBColor(hex: 0xC8326A)
        #expect(color.retinted(from: RGBColor(hex: 0x808080), to: OshiColor.navy.rgb) == color)
    }
}

extension AppTheme: @retroactive CustomTestStringConvertible {
    public var testDescription: String {
        id
    }
}
