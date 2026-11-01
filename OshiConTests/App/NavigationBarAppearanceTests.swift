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

    @Test("書体の大きさは、ダイナミックタイプの文字の大きさに合わせる（標準では iOS の標準のタイトルと同じ大きさ）")
    func titleFontScalesWithContentSize() throws {
        let locale = DomainFixtures.japanese
        let standard = UITraitCollection(preferredContentSizeCategory: .large)
        let larger = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge)
        for (title, size) in [(AppTheme.Typography.BarTitle.large, 34.0), (.inline, 17.0)] {
            let font = try #require(NavigationBarAppearance.titleFont(title, typography: typography, locale: locale, traits: standard))
            let largerFont = try #require(NavigationBarAppearance.titleFont(title, typography: typography, locale: locale, traits: larger))
            // UIFontMetrics の拡大は浮動小数点で計算されるので、ごくわずかな誤差を許す
            #expect(abs(font.pointSize - size) < 0.01)
            #expect(largerFont.pointSize > size)
        }
    }
}
