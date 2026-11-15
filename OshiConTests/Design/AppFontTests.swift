//
//  AppFontTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftUI
import Testing
import UIKit

struct AppFontTests {
    @Test("出荷するテーマの本文の書体を、アプリと Widget Extension の両方に同梱して UIAppFonts で登録する")
    func shippingTextFacesAreBundled() throws {
        let faces = AppTheme.shipping.typography.textFaces
        let fileNames = Set([faces.regular, faces.medium, faces.bold].map { "\($0).ttf" })
        let widget = try #require(Bundle.main.builtInPlugInsURL).appending(path: "OshiConWidgetExtension.appex")
        for bundle in [Bundle.main, try #require(Bundle(url: widget))] {
            let name = bundle.bundleURL.lastPathComponent
            let fonts = try #require(bundle.object(forInfoDictionaryKey: "UIAppFonts") as? [String])
            for fileName in fileNames {
                #expect(fonts.contains(fileName), "\(name) の UIAppFonts に \(fileName) が無い")
                #expect(bundle.url(forResource: fileName, withExtension: nil) != nil, "\(name) に \(fileName) が無い")
            }
        }
        for name in [faces.regular, faces.medium, faces.bold] {
            #expect(UIFont(name: name, size: 17) != nil, "\(name)")
        }
    }

    @Test("アプリの日本語の文言と日本語の見本の文字が、出荷するテーマの本文の書体に字形としてある", arguments: Self.textFaceNames)
    func fontCoversJapaneseText(name: String) throws {
        let font = CTFontCreateWithName(name as CFString, 17, nil)
        #expect(CTFontCopyPostScriptName(font) as String == name)
        let characters = try Self.japaneseCharacters()
        #expect(characters.count > 100)
        let missing = characters.filter { character in
            var utf16 = Array(String(character).utf16)
            var glyphs = [CGGlyph](repeating: 0, count: utf16.count)
            return !CTFontGetGlyphsForCharacters(font, &utf16, &glyphs, utf16.count)
        }
        #expect(missing.isEmpty, "\(name) に字形が無い: \(String(missing))")
    }

    /// 出荷するテーマの本文の書体の PostScript 名。
    nonisolated private static let textFaceNames: [String] = {
        let faces = AppTheme.shipping.typography.textFaces
        return Array(Set([faces.regular, faces.medium, faces.bold])).sorted()
    }()

    /// 文言（日本語の訳。キーも日本語の文言）と、日本語の見本の推し・予定の文字。空白・制御文字と絵文字は除く（システムの書体に任せる）。
    private static func japaneseCharacters() throws -> [Character] {
        var texts: [String] = []
        let bundle = Bundle.main
        let strings = try #require(bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: "ja"))
        let dictionary = try #require(NSDictionary(contentsOf: strings) as? [String: String])
        texts += Array(dictionary.keys) + Array(dictionary.values)
        let plurals = try #require(
            bundle.url(forResource: "Localizable", withExtension: "stringsdict", subdirectory: nil, localization: "ja")
        )
        texts += Self.strings(in: try #require(NSDictionary(contentsOf: plurals)))
        texts += Self.japaneseDates()
        let sample = SampleData.make(
            today: DomainFixtures.day(2026, 10, 18),
            now: DomainFixtures.date(2026, 10, 18, 9, 41),
            language: .japanese
        )
        texts += sample.oshis.map(\.name)
        texts += sample.events.flatMap { [$0.title, $0.venue] }
        let characters = Set(texts.joined()).filter { character in
            !character.isWhitespace && !character.unicodeScalars.contains {
                $0.properties.isEmojiPresentation || $0.properties.generalCategory == .control
            }
        }
        return characters.sorted()
    }

    /// 画面に出る日本語の日付と時刻（12 か月と 7 つの曜日）。
    private static func japaneseDates() -> [String] {
        let locale = DomainFixtures.japanese
        let days = (1...12).flatMap { month in (1...7).map { DomainFixtures.day(2026, month, $0) } }
        let dates = days.flatMap { day in
            [
                EventText.monthDayWeekday(day, locale: locale),
                EventText.spokenMonthDayWeekday(day, locale: locale),
                EventText.fullDate(day, locale: locale),
                EventText.shortDate(day, locale: locale),
                EventText.dateBadge(day, locale: locale)
            ]
        }
        let times = [TimeOfDay(hour: 9, minute: 5), TimeOfDay(hour: 18, minute: 30)].map { EventText.time($0, locale: locale) }
        return dates + times
    }

    private static func strings(in value: Any) -> [String] {
        switch value {
        case let string as String:
            [string]
        case let dictionary as NSDictionary:
            dictionary.allKeys.flatMap { strings(in: $0) } + dictionary.allValues.flatMap { strings(in: $0) }
        case let array as NSArray:
            array.flatMap { strings(in: $0) }
        default:
            []
        }
    }

    @Test(
        "同梱した数字の書体（可変フォント）は、太さを付けるとその太さの字形になる（既定の Thin にならない）",
        arguments: [(UIFont.Weight.regular, 400), (.medium, 500), (.bold, 700)]
    )
    func numeralWeightSelectsVariation(weight: UIFont.Weight, expectedWeightAxis: Int) {
        #expect(UIFont.fontNames(forFamilyName: AppFont.numeralFamily).isEmpty == false)
        let descriptor = UIFontDescriptor(fontAttributes: [.family: AppFont.numeralFamily])
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        let font = UIFont(descriptor: descriptor, size: 20)
        #expect(font.familyName == AppFont.numeralFamily)
        // 可変フォントの wght 軸（'wght' = 0x77676874）の値
        let variation = CTFontCopyVariation(font as CTFont) as? [NSNumber: NSNumber]
        #expect(variation?[NSNumber(value: 0x7767_6874)]?.intValue == expectedWeightAxis)
    }

    @Test("本文に同梱の書体を使うのは日本語のときだけ（ほかの言語はシステムの書体）")
    func bundledTextFaceOnlyForJapanese() {
        #expect(AppFont.usesBundledTextFace(locale: DomainFixtures.japanese))
        #expect(AppFont.usesBundledTextFace(locale: Locale(identifier: "ja_US")))
        for identifier in ["en_US", "zh-Hans_CN", "zh-Hant_TW", "ko_KR", "th_TH", "fr_FR"] {
            #expect(!AppFont.usesBundledTextFace(locale: Locale(identifier: identifier)))
        }
        let typography = AppTheme.shipping.typography
        #expect(typography.text(.body, locale: DomainFixtures.english) == .system(.body, weight: .regular))
        #expect(typography.text(.body, locale: DomainFixtures.japanese) != .system(.body, weight: .regular))
    }

    @Test("太さは regular・medium・bold に丸める")
    func faceForWeight() {
        #expect(AppFont.face(for: .light) == .regular)
        #expect(AppFont.face(for: .regular) == .regular)
        #expect(AppFont.face(for: .medium) == .medium)
        #expect(AppFont.face(for: .semibold) == .bold)
        #expect(AppFont.face(for: .bold) == .bold)
        #expect(AppFont.face(for: .black) == .bold)
    }

    @Test("テキストスタイルの標準の大きさは iOS の既定と同じ")
    func defaultSizes() {
        let styles: [(Font.TextStyle, UIFont.TextStyle)] = [
            (.largeTitle, .largeTitle), (.title, .title1), (.title2, .title2), (.title3, .title3),
            (.headline, .headline), (.body, .body), (.callout, .callout), (.subheadline, .subheadline),
            (.footnote, .footnote), (.caption, .caption1), (.caption2, .caption2)
        ]
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        for (style, uiStyle) in styles {
            #expect(AppFont.defaultSize(of: style) == UIFont.preferredFont(forTextStyle: uiStyle, compatibleWith: traits).pointSize)
        }
    }
}
