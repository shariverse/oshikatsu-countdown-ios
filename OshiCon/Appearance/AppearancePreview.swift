//
//  AppearancePreview.swift
//  OshiCon
//

import CoreGraphics
import Foundation

/// 着せ替えの画面の試着（ホーム・予定の詳細・シェアのカードの見本）と、背景の写真を選ぶときの規則。画面から切り離してテストする。
///
/// 試着は Plus が使えるかにかかわらず、選んだ写真・ON/OFF・暗幕とぼかし・飾りをそのまま映す（実際のホームと詳細に効くかは `AppearanceRendering`）。
nonisolated enum AppearancePreview {
    /// 見本に映す画面。着せ替えの画面と全画面の試着で、見本の下の切り替えから選ぶ。
    nonisolated enum Kind: String, CaseIterable, Identifiable, Sendable {
        /// ホーム（背景の写真と飾りが地に効く）。
        case home
        /// 予定の詳細（上の写真より下の地に効く）。
        case eventDetail
        /// シェアのカード（背景の写真だけが地に効く）。
        case share

        var id: Self {
            self
        }

        /// 切り替えに出す名前（`ホーム`・`予定の詳細`・`シェア`）。
        func title(locale: Locale = .app) -> String {
            switch self {
            case .home:
                String(localized: LocalizedStringResource("ホーム", locale: locale))
            case .eventDetail:
                String(localized: LocalizedStringResource("予定の詳細", locale: locale))
            case .share:
                String(localized: LocalizedStringResource("シェア", locale: locale))
            }
        }

        /// 見本の読み上げの名前（`ホームの見本`・`予定の詳細の見本`・`シェアのカードの見本`）。
        func accessibilityLabel(locale: Locale = .app) -> String {
            switch self {
            case .home:
                String(localized: LocalizedStringResource("ホームの見本", locale: locale))
            case .eventDetail:
                String(localized: LocalizedStringResource("予定の詳細の見本", locale: locale))
            case .share:
                String(localized: LocalizedStringResource("シェアのカードの見本", locale: locale))
            }
        }

        /// 切り替えが文字で収まらないときに出す記号（SF Symbols）。
        var systemImage: String {
            switch self {
            case .home:
                "house"
            case .eventDetail:
                "calendar"
            case .share:
                "square.and.arrow.up"
            }
        }

        /// 暗幕とぼかし・飾りが見本に効くか。シェアのカードは背景の写真だけを地に使い、暗幕とぼかし・飾りは関わらない。
        var showsGroundStyle: Bool {
            self != .share
        }

        /// 並びのとなりの見本（`offset` が 1 なら次、-1 なら前）。端では動かない。
        func advanced(by offset: Int) -> Self {
            let all = Self.allCases
            guard let index = all.firstIndex(of: self) else {
                return self
            }
            return all[min(max(index + offset, 0), all.count - 1)]
        }
    }

    /// 見本のホームと予定の詳細を組む大きさ（pt）。iPhone の縦の画面（背景の写真の枠と同じ約 9:19.5）。これを縮めて見せる。
    static let canvasSize = CGSize(width: 390, height: (390 / PhotoCrop.backgroundAspectRatio).rounded())
    /// 見本のホームと予定の詳細の上の、ステータスバーの分の余白（pt。縮める前の大きさで数える）。
    static let canvasTopInset: CGFloat = 54
    /// 見本に出す「これからの予定」の行の数。
    static let maxRows = 3

    /// 見本を幅 `width`（pt）で見せるときに縮める倍率。
    static func displayScaleFactor(width: CGFloat) -> CGFloat {
        max(width, 0) / canvasSize.width
    }

    /// 見本を高さ `height`（pt）で見せるときの大きさ（pt）。縦横の比は `canvasSize` のまま。
    /// 見せる大きさは画面の大きさで変わる（`AppearancePreviewLayout`）。
    static func displaySize(height: CGFloat) -> CGSize {
        let factor = max(height, 0) / canvasSize.height
        return CGSize(width: canvasSize.width * factor, height: canvasSize.height * factor)
    }

    /// 試着で描くもの。Plus が使えなくても、設定のとおりに描く。
    /// 全画面の試着で長押ししている間（`isComparing`）は、着せ替える前（標準）の見た目にする。
    static func rendering(settings: AppearanceSettings, isComparing: Bool = false) -> AppearanceRendering {
        isComparing ? .standard : AppearanceRendering(settings: settings, isPlusUnlocked: true)
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

    /// 予定の詳細とシェアのカードの見本に出す予定。ホームの見本の先頭のカードと同じ予定（無ければ「これからの予定」の先頭）。
    static func featuredItem(of content: HomeContent) -> HomeContent.Item? {
        content.featured ?? content.upcoming.first
    }

    /// 調整画面で描く写真の短い辺（画素）。縦長の枠の上限（短い辺 `PhotoCropLayout.maximumFrameSide`）の長い辺を、拡大なしで引き伸ばさずに描ける大きさ。
    /// 横長の写真は枠の高さに合わせて写すので、正方形の枠（推しの写真）より大きく読む。
    static func cropDisplayShortSidePixels(displayScale: CGFloat) -> Int {
        let scale = displayScale.isFinite && displayScale > 0 ? displayScale : 1
        return Int((PhotoCropLayout.maximumFrameSide / PhotoCrop.backgroundAspectRatio * scale).rounded(.up))
    }

    /// 見本の読み上げの値。ホームと予定の詳細は、地に描いているものをすべて伝える
    /// （`背景の写真あり、暗幕の濃さ 50%、ぼかしの強さ 40%、推しの写真の飾りあり、飾りの濃さ 40%、飾りの量 25%`）。
    /// シェアのカードは背景の写真だけを地に使うので、写真があるかだけを伝える（`背景の写真あり`）。
    static func accessibilityValue(of rendering: AppearanceRendering, kind: Kind = .home, locale: Locale = .app) -> String {
        var parts: [String] = []
        if let photo = rendering.backgroundPhoto {
            parts.append(String(localized: LocalizedStringResource("背景の写真あり", locale: locale)))
            if kind.showsGroundStyle {
                let scrim = percentText(photo.style.scrim, locale: locale)
                parts.append(String(localized: LocalizedStringResource("暗幕の濃さ \(scrim)", locale: locale)))
                let blur = percentText(photo.style.blur, locale: locale)
                parts.append(String(localized: LocalizedStringResource("ぼかしの強さ \(blur)", locale: locale)))
            }
        } else {
            parts.append(String(localized: LocalizedStringResource("背景の写真なし", locale: locale)))
        }
        guard kind.showsGroundStyle else {
            return EventText.joinedForSpeech(parts, locale: locale)
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

    /// 全画面の試着の見本の読み上げの値。長押ししている間（`isComparing`）は `着せ替える前`、それ以外は見本に映しているもの。
    static func tryOnAccessibilityValue(
        of settings: AppearanceSettings,
        kind: Kind,
        isComparing: Bool,
        locale: Locale = .app
    ) -> String {
        guard !isComparing else {
            return String(localized: LocalizedStringResource("着せ替える前", locale: locale))
        }
        return accessibilityValue(of: rendering(settings: settings), kind: kind, locale: locale)
    }

    /// 暗幕の濃さ・ぼかしの強さ・飾りの濃さ・量（0〜1）を百分率の文字にする（`40%`）。スライダーの読み上げの値と、見本の読み上げの値に使う。
    static func percentText(_ value: Double, locale: Locale = .app) -> String {
        value.formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }
}
