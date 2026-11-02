//
//  NavigationBarAppearanceTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing
import UIKit

@MainActor
struct NavigationBarAppearanceTests {
    private let typography = AppTheme.shipping.typography

    @Test("日本語では、大きいタイトルと小さいタイトルの書体だけをテーマの書体にし、ほかの属性は残す")
    func japaneseSetsTitleFonts() throws {
        let bar = UINavigationBar()
        bar.titleTextAttributes = [.foregroundColor: UIColor.red]
        NavigationBarAppearance.applyTitleFonts(to: bar, typography: typography, locale: DomainFixtures.japanese)

        let title = try #require(bar.titleTextAttributes?[.font] as? UIFont)
        let largeTitle = try #require(bar.largeTitleTextAttributes?[.font] as? UIFont)
        #expect(title.fontName == typography.textFaces.bold)
        #expect(largeTitle.fontName == typography.textFaces.bold)
        #expect(bar.titleTextAttributes?[.foregroundColor] as? UIColor == .red)
    }

    @Test("日本語以外の言語では、バーの書体を設定しない（システムの書体のまま）", arguments: ["en_US", "zh-Hans_CN", "ko_KR", "th_TH"])
    func otherLanguagesLeaveBarUntouched(identifier: String) {
        let bar = UINavigationBar()
        NavigationBarAppearance.applyTitleFonts(to: bar, typography: typography, locale: Locale(identifier: identifier))
        #expect(bar.titleTextAttributes?[.font] == nil)
        #expect(bar.largeTitleTextAttributes?[.font] == nil)
    }

    @Test("大きいタイトルはダイナミックタイプの文字の大きさに合わせて大きくする（標準では iOS の標準のタイトルと同じ 34pt）")
    func largeTitleFontScalesWithContentSize() throws {
        let locale = DomainFixtures.japanese
        let standard = UITraitCollection(preferredContentSizeCategory: .large)
        let larger = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge)
        let font = try #require(NavigationBarAppearance.titleFont(.large, typography: typography, locale: locale, traits: standard))
        let largerFont = try #require(NavigationBarAppearance.titleFont(.large, typography: typography, locale: locale, traits: larger))
        // UIFontMetrics の拡大は浮動小数点で計算されるので、ごくわずかな誤差を許す
        #expect(abs(font.pointSize - 34) < 0.01)
        #expect(largerFont.pointSize > 34)
    }

    @Test(
        "inline のタイトルは、ダイナミックタイプの文字の大きさに関わらず iOS の標準の inline タイトルと同じ 17pt のまま",
        arguments: [UIContentSizeCategory.extraSmall, .large, .accessibilityExtraLarge, .accessibilityExtraExtraExtraLarge]
    )
    func inlineTitleFontKeepsStandardSize(category: UIContentSizeCategory) throws {
        // 高さの決まったバーの中で大きくすると切れるので、アクセシビリティの大きさでも拡大しない（Issue #158）
        let traits = UITraitCollection(preferredContentSizeCategory: category)
        let locale = DomainFixtures.japanese
        let font = try #require(NavigationBarAppearance.titleFont(.inline, typography: typography, locale: locale, traits: traits))
        #expect(font.pointSize == 17)
    }
}
