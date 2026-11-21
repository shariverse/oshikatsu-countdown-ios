//
//  ShareCardRendererTests.swift
//  OshiConTests
//

import Foundation
import ImageIO
@testable import OshiCon
import SwiftUI
import Testing

@MainActor
struct ShareCardRendererTests {
    private let photos = OshiPhotoLibrary(directory: PhotoFixtures.temporaryDirectory())
    private let now = DomainFixtures.date(2026, 10, 15, 9, 0)

    private func content(
        day: CalendarDay = DomainFixtures.day(2026, 10, 18),
        oshi: Oshi? = Oshi(name: "ミナト", color: .navy),
        options: ShareCardContent.Options = .init(),
        locale: Locale = DomainFixtures.japanese
    ) -> ShareCardContent {
        let event = OshiEvent(
            oshiID: oshi?.id,
            kind: .live,
            title: "5th LIVE",
            day: day,
            startTime: TimeOfDay(hour: 17, minute: 0),
            venue: "東京ドーム",
            createdAt: DomainFixtures.date(2020, 1, 1)
        )
        return ShareCardContent(event: event, oshi: oshi, now: now, calendar: DomainFixtures.tokyo, options: options, locale: locale)
    }

    @Test("書き出す画像は 1080 px 四方の PNG（残りがある・当日・終わった・会場あり・英語）")
    func rendersSquarePNG() throws {
        let contents = [
            content(),
            content(day: DomainFixtures.day(2026, 10, 15)),
            content(day: DomainFixtures.day(2026, 10, 1)),
            content(options: .init(includesVenue: true)),
            content(locale: DomainFixtures.english)
        ]
        for card in contents {
            let image = try #require(ShareCardRenderer.render(card, images: ShareCardImages()))
            #expect(image.cgImage.width == 1_080)
            #expect(image.cgImage.height == 1_080)
            let png = try #require(PhotoFixtures.properties(of: image.pngData))
            #expect(png.width == 1_080)
            #expect(png.height == 1_080)
            #expect(png.metadata[kCGImagePropertyPNGDictionary] != nil)
        }
    }

    @Test("ダイナミックタイプの大きさと端末の外観に左右されず、同じ画像になる")
    func ignoresDynamicTypeAndAppearance() throws {
        let card = content(options: .init(includesVenue: true))
        let standard = try #require(ShareCardRenderer.render(ShareCardView(content: card)))
        let large = try #require(
            ShareCardRenderer.render(
                ShareCardView(content: card)
                    .environment(\.dynamicTypeSize, .accessibility5)
                    .environment(\.colorScheme, .light)
            )
        )
        let small = try #require(ShareCardRenderer.render(ShareCardView(content: card).environment(\.dynamicTypeSize, .xSmall)))
        let standardPixels = try #require(PhotoFixtures.pixels(of: standard.pngData))
        let largePixels = try #require(PhotoFixtures.pixels(of: large.pngData))
        let smallPixels = try #require(PhotoFixtures.pixels(of: small.pngData))
        #expect(largePixels.bytes == standardPixels.bytes)
        #expect(smallPixels.bytes == standardPixels.bytes)
    }

    @Test("本文は日本語のときだけテーマの書体、ほかの言語はシステムの書体。どちらも固定の大きさ")
    func textFaceByLocale() {
        let style = ShareCardStyle.shipping
        let faces = AppTheme.shipping.typography.textFaces
        #expect(style.text(size: 18, weight: .bold, locale: DomainFixtures.japanese) == .custom(faces.bold, fixedSize: 18))
        #expect(style.text(size: 12, locale: DomainFixtures.japanese) == .custom(faces.regular, fixedSize: 12))
        for identifier in ["en_US", "zh-Hans_CN", "zh-Hant_TW", "ko_KR", "th_TH", "fr_FR"] {
            #expect(style.text(size: 18, weight: .bold, locale: Locale(identifier: identifier)) == .system(size: 18, weight: .bold))
        }
    }

    @Test("数字はどの言語でも Outfit の固定の大きさ")
    func numeralFace() {
        let typography = AppTheme.shipping.typography
        let expected = Font.custom(AppFont.numeralFamily, fixedSize: 52).weight(typography.numeralWeight).monospacedDigit()
        #expect(ShareCardStyle.shipping.numeral(size: 52) == expected)
        #expect(typography.numeralFamily == AppFont.numeralFamily)
    }

    @Test("推しの写真を読み込み終えてから描く。写真を外すとテーマの模様にする")
    func drawsLoadedPhoto() async throws {
        let fileName = try #require(try await photos.importPhoto(PhotoFixtures.quadrantImageData(width: 400, height: 400)))
        let oshi = Oshi(name: "ミナト", color: .navy, photoFileName: fileName)

        let withPhoto = try #require(await ShareCardRenderer.render(content(oshi: oshi), photos: photos))
        let photoPixels = try #require(PhotoFixtures.pixels(of: withPhoto.pngData))
        // 写真の場所の左上（カードの余白 20pt の内側）
        #expect(photoPixels.matches(x: 180, y: 180, .topLeft))

        let withoutPhoto = try #require(
            await ShareCardRenderer.render(content(oshi: oshi, options: .init(includesPhoto: false)), photos: photos)
        )
        let placeholderPixels = try #require(PhotoFixtures.pixels(of: withoutPhoto.pngData))
        #expect(!placeholderPixels.matches(x: 180, y: 180, .topLeft))
    }

    @Test("地の差し替え口: 着せ替えの画像を地に敷ける。読めなければテーマの地")
    func backgroundSlot() async throws {
        let fileName = try #require(try await photos.importPhoto(PhotoFixtures.quadrantImageData(width: 400, height: 400)))
        let card = content()

        let themed = try #require(await ShareCardRenderer.render(card, photos: photos))
        // カードの外の余白（左の端）は、ダークのテーマの地（端末の外観によらない）
        let themedPixels = try #require(PhotoFixtures.pixels(of: themed.pngData))
        #expect(themedPixels.red(x: 15, y: 300) < 80)

        let style = ShareCardStyle(theme: .shipping, background: .photo(fileName: fileName))
        let dressed = try #require(await ShareCardRenderer.render(card, style: style, photos: photos))
        // 同じところに、写真の左上の赤を暗くした色が出る
        let dressedPixels = try #require(PhotoFixtures.pixels(of: dressed.pngData))
        #expect(dressedPixels.red(x: 15, y: 300) > 100)

        let missing = ShareCardStyle(theme: .shipping, background: .photo(fileName: "\(UUID().uuidString).jpg"))
        let fallback = try #require(await ShareCardRenderer.render(card, style: missing, photos: photos))
        let fallbackPixels = try #require(PhotoFixtures.pixels(of: fallback.pngData))
        #expect(fallbackPixels.bytes == themedPixels.bytes)
    }
}

private extension PhotoFixtures.Pixels {
    /// (x, y) の画素の赤（0〜255）。
    func red(x: Int, y: Int) -> Int {
        Int(bytes[(y * width + x) * 4])
    }
}
