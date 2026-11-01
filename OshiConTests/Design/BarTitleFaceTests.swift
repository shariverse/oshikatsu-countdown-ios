//
//  BarTitleFaceTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftUI
import Testing
import UIKit

struct BarTitleFaceTests {
    private let typography = AppTheme.shipping.typography

    @Test("日本語では、大きいタイトルも小さいタイトルもテーマの書体の太字（標準のタイトルの太さを丸めたもの）")
    func japaneseUsesBoldTextFace() throws {
        let large = try #require(typography.barTitleFace(.large, locale: DomainFixtures.japanese))
        let inline = try #require(typography.barTitleFace(.inline, locale: DomainFixtures.japanese))
        #expect(large == .init(name: typography.textFaces.bold, size: 34))
        #expect(inline == .init(name: typography.textFaces.bold, size: 17))
        #expect(large.name == "KaiseiDecol-Bold")
    }

    @Test(
        "日本語以外の言語では、バーのタイトルはシステムの書体のまま（書体を返さない）",
        arguments: ["en_US", "zh-Hans_CN", "zh-Hant_TW", "ko_KR", "fr_FR", "de_DE", "es_ES", "pt_BR", "it_IT", "th_TH", "id_ID"]
    )
    func otherLanguagesKeepSystemFont(identifier: String) {
        let locale = Locale(identifier: identifier)
        for title in AppTheme.Typography.BarTitle.allCases {
            #expect(typography.barTitleFace(title, locale: locale) == nil)
        }
    }

    @Test("バーのタイトルの書体は、同梱して登録した書体として読み込める", arguments: AppTheme.Typography.BarTitle.allCases)
    func faceResolves(title: AppTheme.Typography.BarTitle) throws {
        let face = try #require(typography.barTitleFace(title, locale: DomainFixtures.japanese))
        let font = try #require(UIFont(name: face.name, size: face.size))
        #expect(font.fontName == face.name)
    }

    @Test("大きさの基準は iOS の標準のタイトルと同じテキストスタイル（大きいタイトルは largeTitle、小さいタイトルは headline）")
    func textStyles() {
        #expect(AppTheme.Typography.BarTitle.large.textStyle == .largeTitle)
        #expect(AppTheme.Typography.BarTitle.inline.textStyle == .headline)
        #expect(AppFont.face(for: AppTheme.Typography.BarTitle.large.systemWeight) == .bold)
        #expect(AppFont.face(for: AppTheme.Typography.BarTitle.inline.systemWeight) == .bold)
    }
}
