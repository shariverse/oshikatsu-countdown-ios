//
//  ShareCardSharingTests.swift
//  OshiConTests
//

import CoreTransferable
import Foundation
@testable import OshiCon
import Testing
import UniformTypeIdentifiers

/// 共有シートに渡す画像と、共有シートの「画像を保存」に要る写真への追加の説明。
@MainActor
struct ShareCardSharingTests {
    /// 対応する 12 言語。
    nonisolated private static let languages = ["en", "ja", "zh-Hans", "zh-Hant", "ko", "fr", "de", "es", "pt-BR", "it", "th", "id"]

    @Test("共有シートには書き出した PNG をそのまま渡す")
    func exportsPNG() async throws {
        let event = OshiEvent(
            oshiID: nil,
            kind: .live,
            title: "5th LIVE",
            day: DomainFixtures.day(2026, 10, 18),
            createdAt: DomainFixtures.date(2020, 1, 1)
        )
        let content = ShareCardContent(
            event: event,
            oshi: nil,
            now: DomainFixtures.date(2026, 10, 15, 9, 0),
            calendar: DomainFixtures.tokyo,
            locale: DomainFixtures.japanese
        )
        let image = try #require(ShareCardRenderer.render(content, images: ShareCardImages()))
        // 書き出した中身を取り出す API は iOS 18.2 から
        if #available(iOS 18.2, *) {
            let exported = try await image.exported(as: .png)
            #expect(exported == image.pngData)
        }
    }

    @Test("写真への追加の説明だけを持ち、写真ライブラリを読む説明は持たない（PhotosPicker は権限が要らない）")
    func photoLibraryUsageDescriptions() throws {
        let description = try #require(Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryAddUsageDescription") as? String)
        #expect(!description.isEmpty)
        #expect(Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") == nil)
    }

    @Test("写真への追加の説明は 12 言語に訳す", arguments: languages)
    func photoLibraryAddUsageDescriptionIsLocalized(language: String) throws {
        let path = try #require(Bundle.main.path(forResource: "InfoPlist", ofType: "strings", inDirectory: nil, forLocalization: language))
        let strings = try #require(NSDictionary(contentsOfFile: path))
        let description = try #require(strings["NSPhotoLibraryAddUsageDescription"] as? String)
        #expect(!description.isEmpty)
        if language != "en" {
            let englishPath = try #require(Bundle.main.path(forResource: "InfoPlist", ofType: "strings", inDirectory: nil, forLocalization: "en"))
            let english = try #require(NSDictionary(contentsOfFile: englishPath))
            #expect(description != english["NSPhotoLibraryAddUsageDescription"] as? String)
        }
    }
}
