//
//  AppearancePreview.swift
//  OshiCon
//

import CoreGraphics
import Foundation

/// 着せ替えの画面の試着（ホームの見本）と、背景の写真を選ぶときの規則。画面から切り離してテストする。
///
/// 試着は Plus が使えるかにかかわらず、選んだ写真・ON/OFF・暗幕とぼかし・飾りをそのまま映す（実際のホームと詳細に効くかは `AppearanceRendering`）。
nonisolated enum AppearancePreview {
    /// 見本のホームを組む大きさ（pt）。iPhone の縦の画面（背景の写真の枠と同じ約 9:19.5）。これを縮めて見せる。
    static let canvasSize = CGSize(width: 390, height: (390 / PhotoCrop.backgroundAspectRatio).rounded())
    /// 見本を見せる幅（pt）。
    static let displayWidth: CGFloat = 180
    /// 見本に出す「これからの予定」の行の数。
    static let maxRows = 3

    /// 見本を見せる大きさに縮める倍率。
    static var displayScaleFactor: CGFloat {
        displayWidth / canvasSize.width
    }

    /// 見本を見せる大きさ（pt）。
    static var displaySize: CGSize {
        CGSize(width: displayWidth, height: canvasSize.height * displayScaleFactor)
    }

    /// 試着で描くもの。Plus が使えなくても、設定のとおりに描く。
    static func rendering(settings: AppearanceSettings) -> AppearanceRendering {
        AppearanceRendering(settings: settings, isPlusUnlocked: true)
    }

    /// 見本に出すホームの中身。登録した予定から先頭の予定が決まればそれを、決まらない（予定が無い・終わった予定だけ）なら見本の推しと予定を出す。
    static func content(events: [OshiEvent], oshis: [Oshi], today: CalendarDay, now: Date, locale: Locale = .app) -> HomeContent {
        let registered = HomeContent(
            events: events,
            oshis: oshis,
            selectedOshiID: nil,
            showsPastEvents: false,
            today: today,
            locale: locale
        )
        guard registered.featured == nil else {
            return registered
        }
        let sample = SampleData.make(today: today, now: now, locale: locale)
        return HomeContent(
            events: sample.events,
            oshis: sample.oshis,
            selectedOshiID: nil,
            showsPastEvents: false,
            today: today,
            locale: locale
        )
    }

    /// 見本に出す「これからの予定」の行。
    static func rows(of content: HomeContent) -> [HomeContent.Item] {
        Array(content.upcoming.prefix(maxRows))
    }

    /// 調整画面で描く写真の短い辺（画素）。縦長の枠の上限（短い辺 `PhotoCropLayout.maximumFrameSide`）の長い辺を、拡大なしで引き伸ばさずに描ける大きさ。
    /// 横長の写真は枠の高さに合わせて写すので、正方形の枠（推しの写真）より大きく読む。
    static func cropDisplayShortSidePixels(displayScale: CGFloat) -> Int {
        let scale = displayScale.isFinite && displayScale > 0 ? displayScale : 1
        return Int((PhotoCropLayout.maximumFrameSide / PhotoCrop.backgroundAspectRatio * scale).rounded(.up))
    }

    /// 見本の読み上げの値（`背景の写真あり、暗幕の濃さ 50%、ぼかしの強さ 40%、推しの写真の飾りあり、飾りの濃さ 40%、飾りの量 25%`）。
    static func accessibilityValue(of rendering: AppearanceRendering, locale: Locale = .app) -> String {
        var parts: [String] = []
        if let photo = rendering.backgroundPhoto {
            parts.append(String(localized: LocalizedStringResource("背景の写真あり", locale: locale)))
            let scrim = percentText(photo.style.scrim, locale: locale)
            parts.append(String(localized: LocalizedStringResource("暗幕の濃さ \(scrim)", locale: locale)))
            let blur = percentText(photo.style.blur, locale: locale)
            parts.append(String(localized: LocalizedStringResource("ぼかしの強さ \(blur)", locale: locale)))
        } else {
            parts.append(String(localized: LocalizedStringResource("背景の写真なし", locale: locale)))
        }
        if let decoration = rendering.decoration {
            parts.append(String(localized: LocalizedStringResource("推しの写真の飾りあり", locale: locale)))
            let opacity = percentText(decoration.opacity, locale: locale)
            parts.append(String(localized: LocalizedStringResource("飾りの濃さ \(opacity)", locale: locale)))
            let amount = percentText(decoration.amount, locale: locale)
            parts.append(String(localized: LocalizedStringResource("飾りの量 \(amount)", locale: locale)))
        } else {
            parts.append(String(localized: LocalizedStringResource("推しの写真の飾りなし", locale: locale)))
        }
        return EventText.joinedForSpeech(parts, locale: locale)
    }

    /// 暗幕の濃さ・ぼかしの強さ・飾りの濃さ・量（0〜1）を百分率の文字にする（`40%`）。スライダーの読み上げの値と、見本の読み上げの値に使う。
    static func percentText(_ value: Double, locale: Locale = .app) -> String {
        value.formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }
}
