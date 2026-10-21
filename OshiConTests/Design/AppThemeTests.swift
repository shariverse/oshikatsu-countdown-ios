//
//  AppThemeTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftUI
import Testing

struct AppThemeTests {
    @Test("既定のテーマの配色は、今の AppPalette の全役割と同じ")
    func standardPaletteMatchesAppPalette() {
        let palette = AppTheme.standard.palette
        #expect(palette.background == AppPalette.background)
        #expect(palette.surface == AppPalette.surface)
        #expect(palette.surfaceContainer == AppPalette.surfaceContainer)
        #expect(palette.surfaceContainerHigh == AppPalette.surfaceContainerHigh)
        #expect(palette.onSurface == AppPalette.onSurface)
        #expect(palette.onSurfaceVariant == AppPalette.onSurfaceVariant)
        #expect(palette.outlineVariant == AppPalette.outlineVariant)
        #expect(palette.brand == AppPalette.brand)
        #expect(palette.onBrand == AppPalette.onBrand)
        #expect(palette.brandContainer == AppPalette.brandContainer)
        #expect(palette.onBrandContainer == AppPalette.onBrandContainer)
        #expect(palette.destructive == AppPalette.destructive)
    }

    @Test("既定のテーマの数字の書体は、今と同じ Font（Outfit・太字・桁の幅をそろえる）")
    func standardNumeralsMatchCurrentFonts() {
        func outfit(_ size: CGFloat, _ style: Font.TextStyle, _ weight: Font.Weight = .bold) -> Font {
            .custom("Outfit", size: size, relativeTo: style).weight(weight).monospacedDigit()
        }
        let typography = AppTheme.standard.typography
        #expect(typography.countdownHero == outfit(88, .largeTitle))
        #expect(typography.countdownLarge == outfit(68, .largeTitle))
        #expect(typography.countdownClock == outfit(32, .title))
        #expect(typography.countdownSmall == outfit(24, .title2))
        #expect(typography.dateBadge == outfit(18, .headline))
        #expect(typography.numeral(size: 40, relativeTo: .title) == outfit(40, .title))
        #expect(typography.numeral(size: 40, weight: .medium, relativeTo: .title) == outfit(40, .title, .medium))
        #expect(AppFont.countdownHero == typography.countdownHero)
        #expect(AppFont.countdownLarge == typography.countdownLarge)
        #expect(AppFont.countdownClock == typography.countdownClock)
        #expect(AppFont.countdownSmall == typography.countdownSmall)
        #expect(AppFont.dateBadge == typography.dateBadge)
        #expect(AppFont.numeral(size: 40, relativeTo: .title) == outfit(40, .title))
    }

    @Test(
        "既定のテーマの本文の書体は、今と同じ Font（日本語は Zen Kaku Gothic New の 3 つの太さ、ほかの言語はシステムの書体）",
        arguments: [Font.Weight.light, .regular, .medium, .semibold, .bold, .heavy]
    )
    func standardTextMatchesCurrentFonts(weight: Font.Weight) {
        let typography = AppTheme.standard.typography
        let face = AppFont.face(for: weight).rawValue
        for style in [Font.TextStyle.largeTitle, .title2, .headline, .body, .subheadline, .caption] {
            let japanese = typography.text(style, weight: weight, locale: DomainFixtures.japanese)
            #expect(japanese == .custom(face, size: AppFont.defaultSize(of: style), relativeTo: style))
            #expect(AppFont.text(style, weight: weight, locale: DomainFixtures.japanese) == japanese)
            let english = typography.text(style, weight: weight, locale: DomainFixtures.english)
            #expect(english == .system(style, weight: weight))
            #expect(AppFont.text(style, weight: weight, locale: DomainFixtures.english) == english)
        }
    }

    @Test("既定のテーマの本文の書体の名前は、同梱の Zen Kaku Gothic New と同じ")
    func standardTextFaces() {
        let faces = AppTheme.standard.typography.textFaces
        #expect(faces.regular == AppFont.TextFace.regular.rawValue)
        #expect(faces.medium == AppFont.TextFace.medium.rawValue)
        #expect(faces.bold == AppFont.TextFace.bold.rawValue)
        #expect(faces.name(for: .light) == "ZenKakuGothicNew-Regular")
        #expect(faces.name(for: .medium) == "ZenKakuGothicNew-Medium")
        #expect(faces.name(for: .semibold) == "ZenKakuGothicNew-Bold")
        #expect(AppTheme.standard.typography.numeralFamily == AppFont.numeralFamily)
        #expect(AppTheme.standard.typography.numeralWeight == .bold)
    }

    @Test("既定のテーマの角の丸みは今の値（先頭のカード 28・まとまり 20・詳細のカード 28・札 8）")
    func standardCornerRadii() {
        let shape = AppTheme.standard.shape
        #expect(shape.heroCard == 28)
        #expect(shape.section == 20)
        #expect(shape.detailCard == 28)
        #expect(shape.tag == 8)
    }

    @Test("既定のテーマは装飾を描かず、写真が無いときは今の縞")
    func standardDecoration() {
        let decoration = AppTheme.standard.decoration
        #expect(decoration.screenBackground == .none)
        #expect(decoration.cardBorder == .none)
        #expect(decoration.headingOrnament == .none)
        #expect(decoration.numeralEffect == .none)
        #expect(decoration.photoPlaceholder == .stripes)
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

    @Test("推し色の文字・薄い地のテーマを受ける版は、既定のテーマでは今の値と同じ", arguments: OshiColor.allCases)
    func oshiColorInStandardTheme(color: OshiColor) {
        #expect(color.text(in: .standard) == color.text)
        #expect(color.textOnSurfaceContainer(in: .standard) == color.textOnSurfaceContainer)
        #expect(color.container(in: .standard) == color.container)
        // 今の値（ライトは推し色のまま・割合 0.45・0.1・0.18 / 0.35 とカードの地）で作った色と同じ
        #expect(AppTheme.standard.oshiText.lightTextDarkenFraction == 0)
        #expect(color.text.light == color.rgb)
        #expect(color.text.dark == color.rgb.mixed(with: .white, fraction: 0.45))
        #expect(color.textOnSurfaceContainer.light == color.rgb.mixed(with: .black, fraction: 0.1))
        #expect(color.container.light == RGBColor.white.mixed(with: color.rgb, fraction: 0.18))
        #expect(color.container.dark == AppPalette.surface.dark.mixed(with: color.rgb, fraction: 0.35))
    }

    @Test("テーマの一覧は既定のテーマから始まり、id は英字で重ならない")
    func allThemes() {
        #expect(AppTheme.all.first == .standard)
        #expect(Set(AppTheme.all.map(\.id)).count == AppTheme.all.count)
        for theme in AppTheme.all {
            #expect(!theme.id.isEmpty)
            #expect(theme.id.allSatisfy { $0.isASCII && $0.isLetter })
            #expect(!theme.displayName.isEmpty)
        }
    }

    @Test("Environment のテーマの既定は既定のテーマ")
    func environmentDefault() {
        #expect(EnvironmentValues().appTheme == .standard)
    }
}

extension AppTheme: @retroactive CustomTestStringConvertible {
    public var testDescription: String {
        id
    }
}
