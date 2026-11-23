//
//  AppearancePreviewTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
@testable import OshiCon
import Testing

struct AppearancePreviewTests {
    private let today = DomainFixtures.day(2026, 10, 18)
    private let now = DomainFixtures.date(2026, 10, 18, 9, 41)
    private let photo = "00000000-0000-0000-0000-000000000001.jpg"

    @Test("試着は Plus が使えなくても、設定のとおりに背景の写真と飾りを映す（実際の画面は標準のまま）")
    func tryOnIgnoresPlus() {
        let settings = AppearanceSettings(isDecorationEnabled: true, intensity: .strong, backgroundPhotoFileName: photo)
        let tryOn = AppearancePreview.rendering(settings: settings)
        #expect(tryOn.backgroundPhoto == AppearanceRendering.BackgroundPhoto(fileName: photo, intensity: .strong))
        #expect(tryOn.showsOshiPhotoDecoration)
        #expect(AppearanceRendering(settings: settings, isPlusUnlocked: false).isStandard)
    }

    @Test("試着でも、背景を OFF にしている・写真が無いときは写真を敷かない")
    func tryOnFollowsToggles() {
        let off = AppearanceSettings(isBackgroundEnabled: false, backgroundPhotoFileName: photo)
        #expect(AppearancePreview.rendering(settings: off).backgroundPhoto == nil)
        #expect(AppearancePreview.rendering(settings: AppearanceSettings()).isStandard)
    }

    @Test("登録した予定に先頭の予定があれば、見本はそれを出す")
    func contentUsesRegisteredEvents() {
        let oshi = Oshi(name: "ミナト", color: .navy)
        var event = DomainFixtures.event(title: "5th LIVE", day: today.adding(days: 7))
        event.oshiID = oshi.id
        let content = AppearancePreview.content(events: [event], oshis: [oshi], today: today, now: now, locale: DomainFixtures.japanese)
        #expect(content.featured?.event.title == "5th LIVE")
        #expect(content.oshis == [oshi])
    }

    @Test("予定が無い・終わった予定だけのときは、見本の推しと予定を出す", arguments: [false, true])
    func contentFallsBackToSample(hasPastEvent: Bool) {
        let events = hasPastEvent ? [DomainFixtures.event(day: today.adding(days: -3))] : []
        let content = AppearancePreview.content(events: events, oshis: [], today: today, now: now, locale: DomainFixtures.japanese)
        #expect(content.featured?.event.title == "ドームツアー 東京公演")
        #expect(content.oshis.count == 6)
        #expect(content.past.isEmpty)
    }

    @Test("見本の行は「これからの予定」の先頭から 3 件まで")
    func rowsAreLimited() {
        let content = AppearancePreview.content(events: [], oshis: [], today: today, now: now, locale: DomainFixtures.japanese)
        let rows = AppearancePreview.rows(of: content)
        #expect(content.upcoming.count > AppearancePreview.maxRows)
        #expect(rows.count == AppearancePreview.maxRows)
        #expect(rows.map(\.id) == content.upcoming.prefix(AppearancePreview.maxRows).map(\.id))

        let single = DomainFixtures.event(day: today.adding(days: 1))
        let one = AppearancePreview.content(events: [single], oshis: [], today: today, now: now, locale: DomainFixtures.japanese)
        #expect(AppearancePreview.rows(of: one).map(\.id) == [single.id])
    }

    @Test("見本は背景の写真の枠と同じ縦長の比率で組み、見せる幅に縮める")
    func canvasMatchesBackgroundAspectRatio() {
        let canvas = AppearancePreview.canvasSize
        #expect(abs(canvas.width / canvas.height - PhotoCrop.backgroundAspectRatio) < 0.001)
        let size = AppearancePreview.displaySize
        #expect(size.width == AppearancePreview.displayWidth)
        #expect(abs(size.width / size.height - canvas.width / canvas.height) < 0.0001)
        #expect(abs(AppearancePreview.displayScaleFactor * canvas.width - size.width) < 0.0001)
    }

    @Test("調整画面で描く写真は、縦長の枠の上限の長い辺を引き伸ばさずに描ける大きさで読む", arguments: [1.0, 2.0, 3.0])
    func cropDisplayPixels(scale: Double) {
        let pixels = AppearancePreview.cropDisplayShortSidePixels(displayScale: CGFloat(scale))
        let frameLongSide = PhotoCropLayout.maximumFrameSide / PhotoCrop.backgroundAspectRatio
        #expect(CGFloat(pixels) >= frameLongSide * CGFloat(scale))
        #expect(CGFloat(pixels) < frameLongSide * CGFloat(scale) + 2)
        // 推しの丸（正方形の枠）より大きく読む
        #expect(CGFloat(pixels) > PhotoCropLayout.maximumFrameSide * CGFloat(scale))
    }

    @Test("画面の倍率が正しくなければ 1 倍として扱う", arguments: [0.0, -1.0, Double.nan, Double.infinity])
    func cropDisplayPixelsWithInvalidScale(scale: Double) {
        let pixels = AppearancePreview.cropDisplayShortSidePixels(displayScale: CGFloat(scale))
        #expect(pixels == AppearancePreview.cropDisplayShortSidePixels(displayScale: 1))
    }

    @Test("見本の読み上げは、背景の写真と強さ・飾りと濃さ・量を伝える")
    func accessibilityValue() {
        let both = AppearanceRendering(
            backgroundPhoto: AppearanceRendering.BackgroundPhoto(fileName: photo, intensity: .medium),
            decoration: OshiPhotoDecorationStyle(opacity: 0.4, amount: 0.25)
        )
        #expect(
            AppearancePreview.accessibilityValue(of: both, locale: DomainFixtures.japanese)
                == "背景の写真あり、強さ 中、推しの写真の飾りあり、飾りの濃さ 40%、飾りの量 25%"
        )
        #expect(AppearancePreview.accessibilityValue(of: .standard, locale: DomainFixtures.japanese) == "背景の写真なし、推しの写真の飾りなし")
        #expect(
            AppearancePreview.accessibilityValue(of: both, locale: DomainFixtures.english)
                == "Background photo on, Strength Medium, Oshi photo decorations on, Decoration opacity 40%, Decoration amount 25%"
        )
    }

    @Test("濃さ・量は百分率で読む（端数は丸める）")
    func percentText() {
        #expect(AppearancePreview.percentText(0.4, locale: DomainFixtures.japanese) == "40%")
        #expect(AppearancePreview.percentText(1, locale: DomainFixtures.english) == "100%")
        #expect(AppearancePreview.percentText(0.333, locale: DomainFixtures.japanese) == "33%")
    }

    @Test("強さの名前は弱・中・強")
    func intensityTitles() {
        #expect(AppearanceIntensity.allCases.map { $0.title(locale: DomainFixtures.japanese) } == ["弱", "中", "強"])
        #expect(AppearanceIntensity.allCases.map { $0.title(locale: DomainFixtures.english) } == ["Light", "Medium", "Strong"])
    }
}
