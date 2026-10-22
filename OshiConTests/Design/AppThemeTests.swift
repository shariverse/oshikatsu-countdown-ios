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

    @Test("星とハートの地の色はグラデーションの色で、文字が乗るのはその色と、模様の色を不透明度の分だけ重ねた色")
    func textGroundsWithSparkles() {
        let top = AdaptiveColor(light: 0xFFFFFF, dark: 0x000000)
        let bottom = AdaptiveColor(light: 0xEEEEEE, dark: 0x111111)
        let ornament = AdaptiveColor(light: 0xFF0000, dark: 0x0000FF)
        let opacity = AppTheme.ScreenBackground.ornamentOpacity
        let sparkles = AppTheme.ScreenBackground.sparkles(gradient: [top, bottom], ornament: ornament)
        let background = AdaptiveColor(light: 0x123456, dark: 0x123456)
        #expect(sparkles.grounds(background: background) == [top, bottom])
        let grounds = sparkles.textGrounds(background: background)
        #expect(grounds.count == 4)
        #expect(Array(grounds.prefix(2)) == [top, bottom])
        #expect(grounds[2].light == top.light.mixed(with: ornament.light, fraction: opacity))
        #expect(grounds[3].dark == bottom.dark.mixed(with: ornament.dark, fraction: opacity))
    }

    @Test("照明の地の色はグラデーションの色で、文字が乗るのはその色と、光の筋の色を不透明度の分だけ重ねた色")
    func textGroundsWithStage() {
        let top = AdaptiveColor(light: 0xFFFFFF, dark: 0x000000)
        let beam = AdaptiveColor(light: 0xFF0000, dark: 0x0000FF)
        let stage = AppTheme.ScreenBackground.stage(gradient: [top], beam: beam)
        let background = AdaptiveColor(light: 0x123456, dark: 0x123456)
        #expect(stage.grounds(background: background) == [top])
        let grounds = stage.textGrounds(background: background)
        #expect(grounds.count == 2)
        #expect(grounds[1].light == top.light.mixed(with: beam.light, fraction: AppTheme.ScreenBackground.beamOpacity))
        #expect(grounds[1].dark == top.dark.mixed(with: beam.dark, fraction: AppTheme.ScreenBackground.beamOpacity))
    }

    @Test("数字の効果が無ければ光は無い。光は推し色の塗りの上では白、地の上では推し色から作る", arguments: OshiColor.allCases)
    func numeralGlow(color: OshiColor) {
        #expect(AppTheme.NumeralEffect.none.glow(for: color, on: .oshiFill) == nil)
        #expect(AppTheme.NumeralEffect.none.glow(for: color, on: .ground) == nil)
        let onFill = AppTheme.NumeralEffect.glow.glow(for: color, on: .oshiFill)
        #expect(onFill?.color == AdaptiveColor(light: .white, dark: .white))
        #expect(onFill?.opacity == AppTheme.NumeralEffect.fillGlowOpacity)
        let onGround = AppTheme.NumeralEffect.glow.glow(for: color, on: .ground)
        #expect(onGround?.color == AdaptiveColor(light: color.rgb, dark: color.rgb))
        #expect(onGround?.opacity == AppTheme.NumeralEffect.groundGlowOpacity)
        let peak = onGround?.peak(over: .white, isDark: false)
        #expect(peak == RGBColor.white.mixed(with: color.rgb, fraction: AppTheme.NumeralEffect.groundGlowOpacity))
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
        #expect(theme.decoration.numeralEffect == .none)
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
}

extension AppTheme: @retroactive CustomTestStringConvertible {
    public var testDescription: String {
        id
    }
}
