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
        let style = AppearanceBackgroundStyle(scrim: 1, blur: 1)
        let settings = AppearanceSettings(isDecorationEnabled: true, backgroundStyle: style, backgroundPhotoFileName: photo)
        let tryOn = AppearancePreview.rendering(settings: settings)
        #expect(tryOn.backgroundPhoto == AppearanceRendering.BackgroundPhoto(fileName: photo, style: style))
        #expect(tryOn.showsOshiPhotoDecoration)
        #expect(AppearanceRendering(settings: settings, isPlusUnlocked: false).isStandard)
    }

    @Test("試着でも、背景を OFF にしている・写真が無いときは写真を敷かない")
    func tryOnFollowsToggles() {
        let off = AppearanceSettings(isBackgroundEnabled: false, backgroundPhotoFileName: photo)
        #expect(AppearancePreview.rendering(settings: off).backgroundPhoto == nil)
        #expect(AppearancePreview.rendering(settings: AppearanceSettings()).isStandard)
    }

    @Test("全画面の試着で長押ししている間は、設定によらず着せ替える前（標準）の見た目にする")
    func comparingShowsStandard() {
        let settings = AppearanceSettings(isDecorationEnabled: true, backgroundPhotoFileName: photo)
        #expect(!AppearancePreview.rendering(settings: settings, isComparing: false).isStandard)
        #expect(AppearancePreview.rendering(settings: settings, isComparing: true).isStandard)
        #expect(AppearancePreview.rendering(settings: settings) == AppearancePreview.rendering(settings: settings, isComparing: false))
    }

    @Test("見本はホーム・予定の詳細・シェアの順に並び、切り替えの名前と読み上げの名前を言語ごとに出す")
    func kinds() {
        #expect(AppearancePreview.Kind.allCases == [.home, .eventDetail, .share])
        #expect(AppearancePreview.Kind.allCases.map { $0.title(locale: DomainFixtures.japanese) } == ["ホーム", "予定の詳細", "シェア"])
        #expect(AppearancePreview.Kind.allCases.map { $0.title(locale: DomainFixtures.english) } == ["Home", "Event Details", "Share"])
        #expect(
            AppearancePreview.Kind.allCases.map { $0.accessibilityLabel(locale: DomainFixtures.japanese) }
                == ["ホームの見本", "予定の詳細の見本", "シェアのカードの見本"]
        )
        #expect(
            AppearancePreview.Kind.allCases.map { $0.accessibilityLabel(locale: DomainFixtures.english) }
                == ["Home preview", "Event details preview", "Share card preview"]
        )
        // 記号はどれも違う（文字が収まらないときに見分けられる）
        #expect(Set(AppearancePreview.Kind.allCases.map(\.systemImage)).count == AppearancePreview.Kind.allCases.count)
    }

    @Test("となりの見本へ送る。端では動かない")
    func kindAdvances() {
        #expect(AppearancePreview.Kind.home.advanced(by: 1) == .eventDetail)
        #expect(AppearancePreview.Kind.eventDetail.advanced(by: 1) == .share)
        #expect(AppearancePreview.Kind.share.advanced(by: 1) == .share)
        #expect(AppearancePreview.Kind.share.advanced(by: -1) == .eventDetail)
        #expect(AppearancePreview.Kind.home.advanced(by: -1) == .home)
        #expect(AppearancePreview.Kind.home.advanced(by: 5) == .share)
        #expect(AppearancePreview.Kind.eventDetail.advanced(by: 0) == .eventDetail)
    }

    @Test("予定の詳細とシェアのカードの見本は、ホームの見本の先頭のカードと同じ予定を出す")
    func featuredItem() {
        let oshi = Oshi(name: "ミナト", color: .navy)
        var event = DomainFixtures.event(title: "5th LIVE", day: today.adding(days: 7))
        event.oshiID = oshi.id
        let registered = AppearancePreview.content(events: [event], oshis: [oshi], today: today, now: now, locale: DomainFixtures.japanese)
        #expect(AppearancePreview.featuredItem(of: registered)?.id == event.id)
        #expect(AppearancePreview.featuredItem(of: registered)?.oshi == oshi)

        // 予定が無ければ、見本の予定
        let sample = AppearancePreview.content(events: [], oshis: [], today: today, now: now, locale: DomainFixtures.japanese)
        #expect(AppearancePreview.featuredItem(of: sample)?.event.title == "ドームツアー 東京公演")
        #expect(AppearancePreview.featuredItem(of: sample)?.id == sample.featured?.id)
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

    @Test("見本は背景の写真の枠と同じ縦長の比率で組み、見せる高さに縮める", arguments: [120.0, 300.0, 607.0])
    func canvasMatchesBackgroundAspectRatio(height: Double) {
        let canvas = AppearancePreview.canvasSize
        #expect(abs(canvas.width / canvas.height - PhotoCrop.backgroundAspectRatio) < 0.001)
        let size = AppearancePreview.displaySize(height: CGFloat(height))
        #expect(abs(size.height - CGFloat(height)) < 0.0001)
        #expect(abs(size.width / size.height - canvas.width / canvas.height) < 0.0001)
        #expect(abs(AppearancePreview.displayScaleFactor(width: size.width) * canvas.width - size.width) < 0.0001)
    }

    @Test("見せる大きさが負なら 0 にする")
    func displaySizeWithNegativeLength() {
        #expect(AppearancePreview.displaySize(height: -10) == .zero)
        #expect(AppearancePreview.displayScaleFactor(width: -10) == 0)
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

    @Test("見本の読み上げは、背景の写真と暗幕の濃さ・ぼかしの強さ、飾りと濃さ・量を伝える")
    func accessibilityValue() {
        let both = AppearanceRendering(
            backgroundPhoto: AppearanceRendering.BackgroundPhoto(fileName: photo, style: .default),
            decoration: OshiPhotoDecorationStyle(opacity: 0.4, amount: 0.25)
        )
        #expect(
            AppearancePreview.accessibilityValue(of: both, locale: DomainFixtures.japanese)
                == "背景の写真あり、暗幕の濃さ 50%、ぼかしの強さ 40%、推しの写真の飾りあり、飾りの濃さ 40%、飾りの量 25%"
        )
        #expect(AppearancePreview.accessibilityValue(of: .standard, locale: DomainFixtures.japanese) == "背景の写真なし、推しの写真の飾りなし")
        #expect(
            AppearancePreview.accessibilityValue(of: both, locale: DomainFixtures.english)
                == "Background photo on, Dimming 50%, Blur 40%, Oshi photo decorations on, Decoration opacity 40%, Decoration amount 25%"
        )

        // 暗幕とぼかしは別々の値を伝える
        let photoOnly = AppearanceRendering(
            backgroundPhoto: AppearanceRendering.BackgroundPhoto(fileName: photo, style: AppearanceBackgroundStyle(scrim: 0, blur: 1)),
            decoration: nil
        )
        #expect(
            AppearancePreview.accessibilityValue(of: photoOnly, locale: DomainFixtures.japanese)
                == "背景の写真あり、暗幕の濃さ 0%、ぼかしの強さ 100%、推しの写真の飾りなし"
        )
    }

    @Test("予定の詳細の見本の読み上げは、ホームの見本と同じく地に描いているものをすべて伝える")
    func accessibilityValueOfEventDetail() {
        let both = AppearanceRendering(
            backgroundPhoto: AppearanceRendering.BackgroundPhoto(fileName: photo, style: .default),
            decoration: OshiPhotoDecorationStyle(opacity: 0.4, amount: 0.25)
        )
        for rendering in [both, .standard] {
            #expect(
                AppearancePreview.accessibilityValue(of: rendering, kind: .eventDetail, locale: DomainFixtures.japanese)
                    == AppearancePreview.accessibilityValue(of: rendering, kind: .home, locale: DomainFixtures.japanese)
            )
        }
        // 見本の種類を渡さなければホーム
        #expect(
            AppearancePreview.accessibilityValue(of: both, locale: DomainFixtures.japanese)
                == AppearancePreview.accessibilityValue(of: both, kind: .home, locale: DomainFixtures.japanese)
        )
    }

    @Test("シェアのカードの見本の読み上げは、背景の写真があるかだけを伝える（暗幕とぼかし・飾りはカードに関わらない）")
    func accessibilityValueOfShare() {
        let both = AppearanceRendering(
            backgroundPhoto: AppearanceRendering.BackgroundPhoto(fileName: photo, style: .default),
            decoration: OshiPhotoDecorationStyle(opacity: 0.4, amount: 0.25)
        )
        #expect(AppearancePreview.accessibilityValue(of: both, kind: .share, locale: DomainFixtures.japanese) == "背景の写真あり")
        #expect(AppearancePreview.accessibilityValue(of: both, kind: .share, locale: DomainFixtures.english) == "Background photo on")
        let decorationOnly = AppearanceRendering(backgroundPhoto: nil, decoration: .default)
        #expect(AppearancePreview.accessibilityValue(of: decorationOnly, kind: .share, locale: DomainFixtures.japanese) == "背景の写真なし")
        #expect(AppearancePreview.accessibilityValue(of: .standard, kind: .share, locale: DomainFixtures.japanese) == "背景の写真なし")
        #expect(!AppearancePreview.Kind.share.showsGroundStyle)
        #expect(AppearancePreview.Kind.home.showsGroundStyle)
        #expect(AppearancePreview.Kind.eventDetail.showsGroundStyle)
    }

    @Test("全画面の試着の見本の読み上げは、長押ししている間は「着せ替える前」、それ以外は Plus によらず設定のとおり")
    func tryOnAccessibilityValue() {
        let settings = AppearanceSettings(isDecorationEnabled: true, backgroundPhotoFileName: photo)
        #expect(
            AppearancePreview.tryOnAccessibilityValue(of: settings, kind: .home, isComparing: false, locale: DomainFixtures.japanese)
                == "背景の写真あり、暗幕の濃さ 50%、ぼかしの強さ 40%、推しの写真の飾りあり、飾りの濃さ 40%、飾りの量 25%"
        )
        #expect(
            AppearancePreview.tryOnAccessibilityValue(of: settings, kind: .share, isComparing: false, locale: DomainFixtures.japanese)
                == "背景の写真あり"
        )
        for kind in AppearancePreview.Kind.allCases {
            #expect(
                AppearancePreview.tryOnAccessibilityValue(of: settings, kind: kind, isComparing: true, locale: DomainFixtures.japanese)
                    == "着せ替える前"
            )
            #expect(
                AppearancePreview.tryOnAccessibilityValue(of: settings, kind: kind, isComparing: true, locale: DomainFixtures.english)
                    == "Before"
            )
        }
    }

    @Test("暗幕・ぼかし・濃さ・量は百分率で読む（端数は丸める）")
    func percentText() {
        #expect(AppearancePreview.percentText(0.4, locale: DomainFixtures.japanese) == "40%")
        #expect(AppearancePreview.percentText(1, locale: DomainFixtures.english) == "100%")
        #expect(AppearancePreview.percentText(0.333, locale: DomainFixtures.japanese) == "33%")
    }
}
