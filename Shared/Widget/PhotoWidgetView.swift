//
//  PhotoWidgetView.swift
//  OshiCon
//

import SwiftUI
import WidgetKit

/// 推しの写真ウィジェット（Plus。予定 1 件）の中身。小（2×2）は写真を全面に敷いて日数と予定名を、
/// 中（4×2）は左に写真、右の推し色の塗りに推し名・予定名・日数・日付を出す。写真が無い推しは推し色の模様（`ThemePhotoPlaceholder`）。
///
/// 写真は tinted などの 1 色の描き方でも見えるよう、地（`containerBackground`。1 色の描き方では外される）ではなく中身に置く。
/// そのため Widget 側では `contentMarginsDisabled()` にし、余白はこの View が付ける。
/// 写真の上の文字の後ろには暗幕を敷く。1 色の描き方では暗幕を敷かず、写真を白黒で薄く描く（`PhotoWidgetAppearance`）。
/// Plus でないときは、写真と文字を薄くして「Plus で使えます」を重ねる。
/// 形は引数で受ける（`widgetFamily` は Environment に入れられないので、アプリの Preview でも形を選べるように）。
/// アプリの Preview からもウィジェットの大きさの枠で描けるよう、Widget Extension ではなくここに置く。
struct PhotoWidgetView: View {
    /// ホーム画面の形。
    enum Family: CaseIterable {
        case systemSmall
        case systemMedium
    }

    let content: PhotoWidgetContent
    let family: Family
    /// ウィジェットの大きさに縮めて読んだ推しの写真（`WidgetPhotoLoader`）。無い・読めないときは nil（推し色の模様）。
    var photo: CGImage?
    /// 描き方。nil ならウィジェットの描き方（Environment）に従う。アプリの Preview で tinted を見るときに渡す。
    var renderingMode: WidgetRenderingMode?

    /// 余白が分からないとき（アプリの中）の余白。ウィジェットのシステムの既定の余白と同じ。
    private static let fallbackMargin: CGFloat = 16
    /// 暗幕の上の端をぼかす高さ。
    private static let scrimFadeHeight: CGFloat = 40
    /// 中の写真の右の端を推し色の塗りにつなぐ幅。
    private static let photoEdgeFadeWidth: CGFloat = 24

    @Environment(\.widgetRenderingMode) private var environmentRenderingMode
    @Environment(\.widgetContentMargins) private var widgetContentMargins
    @Environment(\.appTheme) private var theme

    var body: some View {
        Group {
            switch content {
            case let .event(event):
                eventView(event)
                    .widgetURL(event.link.url)
            case .notSelected:
                message(title: "予定を選んでください", detail: "長押しして「ウィジェットを編集」から選びます")
            case .missing:
                message(title: "予定が見つかりません", detail: "長押しして「ウィジェットを編集」から選び直します")
            case .unavailable:
                message(title: "データを読み込めませんでした", detail: "しばらくしてからもう一度表示します")
            }
        }
        .containerBackground(Self.containerColor(for: content, in: theme).color, for: .widget)
        .environment(\.locale, .app)
    }

    /// ウィジェットの地。予定は推し色の塗り（写真の後ろと、中の右側）、ほかはカードの地。
    static func containerColor(for content: PhotoWidgetContent, in theme: AppTheme) -> AdaptiveColor {
        switch content {
        case let .event(event):
            AdaptiveColor(light: event.color.rgb, dark: event.color.rgb)
        case .notSelected, .missing, .unavailable:
            theme.palette.surface
        }
    }

    private func appearance(for event: PhotoWidgetContent.Event) -> PhotoWidgetAppearance {
        PhotoWidgetAppearance(
            isFullColor: (renderingMode ?? environmentRenderingMode) == .fullColor,
            isPlusUnlocked: event.isPlusUnlocked
        )
    }

    /// 余白。`contentMarginsDisabled()` にしても、システムの既定の余白が入る。アプリの中では 0 なので既定の値にする。
    private var margins: EdgeInsets {
        guard widgetContentMargins == EdgeInsets() else {
            return widgetContentMargins
        }
        let margin = Self.fallbackMargin
        return EdgeInsets(top: margin, leading: margin, bottom: margin, trailing: margin)
    }

    // MARK: - 予定

    private func eventView(_ event: PhotoWidgetContent.Event) -> some View {
        let appearance = self.appearance(for: event)
        return Group {
            switch family {
            case .systemSmall:
                small(event, appearance: appearance)
            case .systemMedium:
                medium(event, appearance: appearance)
            }
        }
        .overlay {
            if appearance.showsPlusBadge {
                plusBadge(appearance: appearance)
                    .padding(margins)
            }
        }
        .foregroundStyle(event.color.onFill)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(event.accessibilityLabel)
        .accessibilityValue(appearance.showsPlusBadge ? Text("Plus で使えます") : Text(verbatim: ""))
    }

    /// 小: 写真を全面に敷き、下に日数と予定名を暗幕の上に重ねる。
    private func small(_ event: PhotoWidgetContent.Event, appearance: PhotoWidgetAppearance) -> some View {
        ZStack(alignment: .bottomLeading) {
            photoLayer(event, appearance: appearance)
            VStack(alignment: .leading, spacing: 0) {
                countdown(event, numberSize: 40)
                Text(event.title)
                    .font(theme.typography.text(.subheadline, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .opacity(appearance.eventOpacity)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(margins)
            .background {
                if appearance.showsScrim {
                    scrim
                }
            }
        }
    }

    /// 中: 左に写真（高さいっぱいの正方形）、右の推し色の塗りに推し名・予定名・日数・日付。
    private func medium(_ event: PhotoWidgetContent.Event, appearance: PhotoWidgetAppearance) -> some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                photoLayer(event, appearance: appearance)
                    .frame(width: proxy.size.height)
                    .overlay(alignment: .trailing) {
                        if appearance.showsScrim {
                            // 写真の右の端を推し色の塗りにぼかしてつなぐ
                            LinearGradient(
                                colors: [event.color.fill.opacity(0), event.color.fill],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: Self.photoEdgeFadeWidth)
                            .accessibilityHidden(true)
                        }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.heading)
                        .font(theme.typography.text(.caption, weight: .bold))
                        .lineLimit(1)
                        .opacity(0.9)
                    Text(event.title)
                        .font(theme.typography.text(.subheadline, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 4)
                    countdown(event, numberSize: 44)
                    Text(event.dateText)
                        .font(theme.typography.text(.caption, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .opacity(0.9)
                }
                .opacity(appearance.eventOpacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(EdgeInsets(top: margins.top, leading: 12, bottom: margins.bottom, trailing: margins.trailing))
            }
        }
    }

    /// 推しの写真。写真が無い・読めないときは推し色の模様。1 色の描き方では白黒にして色合いを乗せる。
    private func photoLayer(_ event: PhotoWidgetContent.Event, appearance: PhotoWidgetAppearance) -> some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if let photo {
                    Image(decorative: photo, scale: 1)
                        .resizable()
                        .desaturatedWhenAccented()
                        .scaledToFill()
                        .grayscale(appearance.isMonochrome ? 1 : 0)
                } else {
                    ThemePhotoPlaceholder(color: event.color)
                }
            }
            .clipped()
            .opacity(appearance.photoOpacity)
            .accessibilityHidden(true)
    }

    /// 写真の上の文字の後ろの暗幕。文字の高さに合わせて敷き、上の端はぼかす。
    private var scrim: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black.opacity(PhotoWidgetAppearance.scrimOpacity)], startPoint: .top, endPoint: .bottom)
                .frame(height: Self.scrimFadeHeight)
            Color.black.opacity(PhotoWidgetAppearance.scrimOpacity)
        }
        .padding(.top, -Self.scrimFadeHeight)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    /// 残り日数。桁が多いときは数字を小さくして 1 行に収める。
    @ViewBuilder private func countdown(_ event: PhotoWidgetContent.Event, numberSize: CGFloat) -> some View {
        switch event.status {
        case .upcoming:
            let parts = event.countdownParts
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if !parts.prefix.isEmpty {
                    Text(parts.prefix)
                        .font(theme.typography.text(.caption, weight: .bold))
                        .lineLimit(1)
                }
                Text(parts.number)
                    .font(theme.typography.numeral(size: numberSize, relativeTo: .largeTitle))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                if !parts.suffix.isEmpty {
                    Text(parts.suffix)
                        .font(theme.typography.text(.caption, weight: .bold))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        case .today:
            Text(EventText.today(locale: event.locale))
                .font(theme.typography.text(.title, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        case .ended:
            Text(event.countdownText)
                .font(theme.typography.text(.title3, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    /// Plus でないときに見本に重ねる「Plus で使えます」。1 色の描き方では塗りと文字が同じ色になるので輪郭にする。
    @ViewBuilder private func plusBadge(appearance: PhotoWidgetAppearance) -> some View {
        let label = Label("Plus で使えます", systemImage: "lock.fill")
            .font(theme.typography.text(.caption, weight: .bold))
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        if appearance.isMonochrome {
            label
                .overlay(Capsule().strokeBorder(lineWidth: 1.5))
                .widgetAccentable()
        } else {
            label
                .foregroundStyle(theme.palette.onBrand.color)
                .background(theme.palette.brand.color, in: Capsule())
        }
    }

    // MARK: - 案内

    private func message(title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(theme.typography.text(.subheadline, weight: .bold))
                .foregroundStyle(theme.palette.onSurface.color)
            Text(detail)
                .font(theme.typography.text(.caption))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(margins)
        .widgetURL(WidgetLink.home.url)
    }
}

private extension Image {
    /// tinted などの 1 色の描き方で、写真を白黒にして色合いを乗せる（iOS 18 から。iOS 17 には 1 色の描き方が無い）。
    @ViewBuilder func desaturatedWhenAccented() -> some View {
        if #available(iOS 18.0, *) {
            widgetAccentedRenderingMode(.desaturated)
        } else {
            self
        }
    }
}
