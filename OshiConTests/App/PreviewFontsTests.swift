//
//  PreviewFontsTests.swift
//  OshiConTests
//

import CoreText
import Foundation
@testable import OshiCon
import Testing
import UIKit

struct PreviewFontsTests {
    @Test("テーマ案の書体のファイルがすべて DEBUG のバンドルにあり、登録すると PostScript 名で読める")
    func fontsAreBundledAndRegistered() {
        #expect(PreviewFonts.fontURLs().count == PreviewFonts.fileNames.count)
        PreviewFonts.registerIfNeeded()
        PreviewFonts.registerIfNeeded()
        for name in PreviewFonts.fileNames {
            #expect(UIFont(name: name, size: 17) != nil, "\(name)")
        }
    }

    @Test("テーマ案の書体のライセンス文がそれぞれあり、SIL OFL 1.1 の文", arguments: PreviewFonts.licenseFileNames)
    func licenseIsBundled(name: String) throws {
        let url = try #require(Bundle.main.url(forResource: name, withExtension: "txt"))
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("SIL OPEN FONT LICENSE Version 1.1"))
    }

    @Test("テーマ案の書体とライセンス文は、Release の構成で出荷物から外す名前に当たる（同梱の書体は外さない）")
    func previewFontsAreExcludedFromRelease() throws {
        // テストは Simulator で動くので、リポジトリの Configs/Release.xcconfig をソースの場所から読む
        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let config = repository.appendingPathComponent("Configs/Release.xcconfig")
        let text = try String(contentsOf: config, encoding: .utf8)
        let line = try #require(text.split(separator: "\n").first { $0.hasPrefix("EXCLUDED_SOURCE_FILE_NAMES") })
        let patterns = line.split(separator: "=", maxSplits: 1)[1].split(separator: " ").map(String.init)
        func isExcluded(_ fileName: String) -> Bool {
            patterns.contains { fnmatch($0, fileName, 0) == 0 }
        }
        let licenses = PreviewFonts.licenseFileNames.filter { $0 != "ZenKakuGothicNew-OFL" }
        for fileName in PreviewFonts.fileNames.map({ "\($0).ttf" }) + licenses.map({ "\($0).txt" }) {
            #expect(isExcluded(fileName), "\(fileName)")
        }
        let bundled = AppFont.TextFace.allCases.map { "\($0.rawValue).ttf" }
            + ["Outfit-Variable.ttf", "Outfit-OFL.txt", "ZenKakuGothicNew-OFL.txt"]
        for fileName in bundled {
            #expect(!isExcluded(fileName), "\(fileName)")
        }
    }

    @Test("アプリの日本語の文言と日本語の見本の文字が、テーマ案のどの書体にも字形としてある", arguments: PreviewFonts.fileNames)
    func fontCoversJapaneseText(name: String) throws {
        PreviewFonts.registerIfNeeded()
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

    /// 文言（日本語の訳。キーも日本語の文言）と、日本語の見本の推し・予定の文字。空白・制御文字と絵文字は除く（システムの書体に任せる）。
    private static func japaneseCharacters() throws -> [Character] {
        var texts: [String] = []
        let bundle = Bundle.main
        let strings = try #require(bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: "ja"))
        let dictionary = try #require(NSDictionary(contentsOf: strings) as? [String: String])
        texts += Array(dictionary.keys) + Array(dictionary.values)
        if let plurals = bundle.url(forResource: "Localizable", withExtension: "stringsdict", subdirectory: nil, localization: "ja"),
           let dictionary = NSDictionary(contentsOf: plurals) {
            texts += Self.strings(in: dictionary)
        }
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

    private static func strings(in value: Any) -> [String] {
        switch value {
        case let string as String:
            [string]
        case let dictionary as NSDictionary:
            dictionary.allValues.flatMap { strings(in: $0) }
        case let array as NSArray:
            array.flatMap { strings(in: $0) }
        default:
            []
        }
    }
}

struct PreviewThemeLaunchOptionTests {
    @Test("起動引数が無ければテーマ案の見本にしない")
    func noArgument() {
        #expect(LaunchOptions.previewTheme(arguments: ["OshiCon", "-useInMemoryStore"]) == nil)
    }

    @Test("起動引数の id のテーマにする。知らない id・id が無いときは既定のテーマ")
    func themeFromArgument() {
        for theme in AppTheme.all {
            #expect(LaunchOptions.previewTheme(arguments: ["OshiCon", "-previewTheme", theme.id]) == theme)
        }
        #expect(LaunchOptions.previewTheme(arguments: ["OshiCon", "-previewTheme", "unknownTheme"]) == .standard)
        #expect(LaunchOptions.previewTheme(arguments: ["OshiCon", "-previewTheme"]) == .standard)
        #expect(AppTheme.theme(id: "unknownTheme") == .standard)
        #expect(AppTheme.theme(id: "standard") == .standard)
    }
}
