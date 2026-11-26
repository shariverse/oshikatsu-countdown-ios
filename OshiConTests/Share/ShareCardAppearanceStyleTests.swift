//
//  ShareCardAppearanceStyleTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

/// 予定の詳細からシェアのプレビューに渡すカードの見た目（Plus の着せ替え）。
@MainActor
struct ShareCardAppearanceStyleTests {
    private let fileName = "\(UUID().uuidString).jpg"

    private func style(_ settings: AppearanceSettings, isPlusUnlocked: Bool) -> ShareCardStyle {
        .appearance(AppearanceRendering(settings: settings, isPlusUnlocked: isPlusUnlocked))
    }

    @Test("Plus で背景の写真を ON にしていて写真があれば、その写真を地にする")
    func photoBackgroundWhenPlusAndEnabled() {
        let settings = AppearanceSettings(isBackgroundEnabled: true, backgroundPhotoFileName: fileName)
        #expect(style(settings, isPlusUnlocked: true) == ShareCardStyle(theme: .shipping, background: .photo(fileName: fileName)))
        // 暗幕・ぼかしと飾りはカードに関わらない
        let decorated = AppearanceSettings(
            isBackgroundEnabled: true,
            isDecorationEnabled: true,
            backgroundStyle: AppearanceBackgroundStyle(scrim: 1, blur: 1),
            backgroundPhotoFileName: fileName
        )
        #expect(style(decorated, isPlusUnlocked: true) == ShareCardStyle(theme: .shipping, background: .photo(fileName: fileName)))
    }

    @Test("Plus でない（解約・期限切れを含む）ときは出荷するテーマのカード")
    func shippingWhenLocked() {
        let settings = AppearanceSettings(isBackgroundEnabled: true, isDecorationEnabled: true, backgroundPhotoFileName: fileName)
        #expect(style(settings, isPlusUnlocked: false) == .shipping)
    }

    @Test("背景が OFF・写真が無い・写真の置き場所の外を指す・飾りだけのときは出荷するテーマのカード")
    func shippingWhenNoBackgroundPhoto() {
        let cases = [
            AppearanceSettings(isBackgroundEnabled: false, backgroundPhotoFileName: fileName),
            AppearanceSettings(isBackgroundEnabled: true, backgroundPhotoFileName: nil),
            AppearanceSettings(isBackgroundEnabled: true, backgroundPhotoFileName: "../\(fileName)"),
            AppearanceSettings(isBackgroundEnabled: true, isDecorationEnabled: true, backgroundPhotoFileName: nil)
        ]
        for settings in cases {
            #expect(style(settings, isPlusUnlocked: true) == .shipping, "\(settings)")
        }
        #expect(ShareCardStyle.appearance(.standard) == .shipping)
    }

    @Test("カードの地の画像は、着せ替えの背景の写真の置き場所から読む（推しの写真は推しの写真の置き場所から）")
    func loadsBackgroundFromAppearancePhotos() async throws {
        let oshiPhotos = OshiPhotoLibrary(directory: PhotoFixtures.temporaryDirectory())
        let backgroundPhotos = OshiPhotoLibrary(directory: PhotoFixtures.temporaryDirectory())
        let oshiPhoto = try #require(try await oshiPhotos.importPhoto(PhotoFixtures.imageData(width: 400, height: 400)))
        let background = try #require(try await backgroundPhotos.importPhoto(PhotoFixtures.imageData(width: 400, height: 400)))
        let oshi = Oshi(name: "ミナト", color: .navy, photoFileName: oshiPhoto)
        let event = OshiEvent(
            oshiID: oshi.id,
            kind: .live,
            title: "5th LIVE",
            day: DomainFixtures.day(2026, 10, 18),
            createdAt: DomainFixtures.date(2020, 1, 1)
        )
        let content = ShareCardContent(
            event: event,
            oshi: oshi,
            now: DomainFixtures.date(2026, 10, 15, 9, 0),
            calendar: DomainFixtures.tokyo,
            options: .init(),
            locale: DomainFixtures.japanese
        )
        let style = ShareCardStyle(theme: .shipping, background: .photo(fileName: background))

        let images = await ShareCardImages.load(content: content, style: style, photos: oshiPhotos, backgroundPhotos: backgroundPhotos)
        #expect(images.photo != nil)
        #expect(images.background != nil)

        // 置き場所を分けないと、推しの写真の置き場所に無い地の画像は読めない（テーマの地になる）
        let shared = await ShareCardImages.load(content: content, style: style, photos: oshiPhotos)
        #expect(shared.photo != nil)
        #expect(shared.background == nil)
    }
}

/// 予定の詳細で、着せ替えの地を上の写真より下にだけ敷くための、上の写真の下端。
@MainActor
struct AppearanceDetailHeaderPositionTests {
    @Test("上の写真の下端を受け取る。画面の上に隠れた分は 0")
    func clampsToTop() {
        let position = AppearanceDetailHeaderPosition()
        #expect(position.bottom == 0)
        position.update(headerMaxY: 300)
        #expect(position.bottom == 300)
        // スクロールで上の写真が上へ動く
        position.update(headerMaxY: 120)
        #expect(position.bottom == 120)
        // 上の写真が画面の上に隠れた
        position.update(headerMaxY: -40)
        #expect(position.bottom == 0)
        // 引き下げて上の写真が下へ動く
        position.update(headerMaxY: 360)
        #expect(position.bottom == 360)
    }
}
