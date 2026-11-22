//
//  ShareCardView.swift
//  OshiCon
//

import SwiftUI

/// シェアのカード（正方形）。地（テーマの地か、着せ替えの画像）の上に、推しの写真（無ければテーマの模様）と推し色の塗りのカードを 1 枚につないで置き、
/// 下に透かしを小さく出す。文字は推し色の塗りの上にだけ置き、写真の上には重ねない。
/// 大きさは `ShareCardSize.points` の固定で、ダイナミックタイプに左右されない（書き出す画像を同じにする）。
/// 写真は `ShareCardImages` で読み込み終えてから渡す。
struct ShareCardView: View {
    let content: ShareCardContent
    var style: ShareCardStyle = .shipping
    var images = ShareCardImages()

    private static let padding: CGFloat = 20
    private static let cardPadding: CGFloat = 16

    private var theme: AppTheme {
        style.theme
    }

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                photo
                event
            }
            .clipShape(cardShape)
            .themeCardBorder(cardShape)
            watermark
        }
        .padding(Self.padding)
        .frame(width: ShareCardSize.points, height: ShareCardSize.points)
        .background { background }
        .clipped()
        .environment(\.appTheme, theme)
        .environment(\.colorScheme, style.colorScheme)
        .environment(\.locale, content.locale)
        .dynamicTypeSize(.large)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.shape.heroCard)
    }

    // MARK: 地

    @ViewBuilder private var background: some View {
        if case .photo = style.background, let image = images.background {
            Color.black
                .overlay {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFill()
                }
                .overlay(Color.black.opacity(ShareCardStyle.photoBackgroundScrimOpacity))
                .clipped()
                .accessibilityHidden(true)
        } else {
            ThemeScreenBackground()
        }
    }

    // MARK: 写真

    /// 推しの写真。写真が無い・外した・読めないときは推し色の模様。カードの残りの高さを埋める。
    private var photo: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                ZStack {
                    ThemePhotoPlaceholder(color: content.color)
                    if let image = images.photo {
                        Image(decorative: image, scale: 1)
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    // MARK: 予定

    /// 推し色の塗りに白い文字で、予定名・日付・会場・日数。
    private var event: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(content.title)
                .font(style.text(size: 18, weight: .bold, locale: content.locale))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.dateText)
                        .font(style.text(size: 12, weight: .bold, locale: content.locale))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    if let venue = content.venueText {
                        Text(venue)
                            .font(style.text(size: 12, locale: content.locale))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .opacity(0.9)
                    }
                }
                Spacer(minLength: 0)
                days
                    .layoutPriority(1)
            }
        }
        .foregroundStyle(content.color.onFill)
        .padding(Self.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(content.color.fill)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var days: some View {
        switch content.days {
        case let .remaining(parts), let .ago(parts):
            // 桁が多いときは数字を小さくして 1 行に収める
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                if !parts.prefix.isEmpty {
                    Text(parts.prefix)
                        .font(style.text(size: 15, weight: .bold, locale: content.locale))
                        .lineLimit(1)
                        .fixedSize()
                }
                Text(parts.number)
                    .font(style.numeral(size: 52))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if !parts.suffix.isEmpty {
                    Text(parts.suffix)
                        .font(style.text(size: 15, weight: .bold, locale: content.locale))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        case let .today(startTime):
            VStack(alignment: .trailing, spacing: 0) {
                Text(EventText.today(locale: content.locale))
                    .font(style.text(size: 32, weight: .bold, locale: content.locale))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let startTime {
                    Text(startTime)
                        .font(style.text(size: 13, weight: .bold, locale: content.locale))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    // MARK: 透かし

    /// 透かし（ブランド名）。カードの外の地の上に小さく出し、文字には重ねない。
    private var watermark: some View {
        Text(content.watermark)
            .font(style.text(size: 11, weight: .bold, locale: content.locale))
            .foregroundStyle(watermarkColor)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityHidden(true)
    }

    private var watermarkColor: Color {
        switch style.background {
        case .theme:
            theme.palette.onSurfaceVariant.color
        case .photo:
            images.background == nil ? theme.palette.onSurfaceVariant.color : .white
        }
    }
}

// MARK: - Preview

/// Preview の見本。
private enum ShareCardPreview {
    static let calendar = Calendar.autoupdatingCurrent

    static func content(
        title: String = "5th LIVE 東京公演",
        daysFromToday: Int = 12,
        startTime: TimeOfDay? = TimeOfDay(hour: 18, minute: 0),
        venue: String = "東京ドーム",
        oshi: Oshi? = Oshi(name: "LUMINA", color: .pink, photoFileName: "\(UUID().uuidString).jpg"),
        options: ShareCardContent.Options = .init(),
        locale: Locale = Locale(identifier: "ja_JP")
    ) -> ShareCardContent {
        let date = calendar.date(byAdding: .day, value: daysFromToday, to: .now) ?? .now
        let event = OshiEvent(
            oshiID: oshi?.id,
            kind: .live,
            title: title,
            day: CalendarDay(date, calendar: calendar),
            startTime: startTime,
            venue: venue,
            createdAt: .now
        )
        return ShareCardContent(event: event, oshi: oshi, now: .now, calendar: calendar, options: options, locale: locale)
    }

    /// 推しの写真の代わりの画像。
    static var photo: CGImage? {
        ImageRenderer(
            content: LinearGradient(colors: [.pink, .purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(Image(systemName: "person.fill").font(.system(size: 160)).foregroundStyle(.white.opacity(0.8)))
                .frame(width: 360, height: 360)
        ).cgImage
    }
}

#Preview("写真あり") {
    ShareCardView(content: ShareCardPreview.content(), images: ShareCardImages(photo: ShareCardPreview.photo))
}

#Preview("写真なし・会場あり") {
    ShareCardView(content: ShareCardPreview.content(options: .init(includesVenue: true, includesPhoto: false)))
}

#Preview("終わった予定") {
    ShareCardView(content: ShareCardPreview.content(daysFromToday: -3, oshi: Oshi(name: "ミナト", color: .navy)))
}

#Preview("当日") {
    ShareCardView(content: ShareCardPreview.content(daysFromToday: 0), images: ShareCardImages(photo: ShareCardPreview.photo))
}

#Preview("長い予定名・推しなし") {
    ShareCardView(
        content: ShareCardPreview.content(
            title: "LUMINA 5th Anniversary LIVE TOUR 2026 〜永遠のきらめき〜 東京ドーム公演 2 日目",
            daysFromToday: 1_234,
            venue: "東京ドーム（東京都文京区後楽 1-3-61）",
            oshi: nil,
            options: .init(includesVenue: true)
        )
    )
}

#Preview("英語") {
    ShareCardView(
        content: ShareCardPreview.content(
            title: "5th LIVE Tokyo",
            venue: "Tokyo Dome",
            options: .init(includesVenue: true),
            locale: Locale(identifier: "en_US")
        ),
        images: ShareCardImages(photo: ShareCardPreview.photo)
    )
}

#Preview("着せ替えの地（Plus の差し替え口）") {
    let photo = ShareCardPreview.photo
    ShareCardView(
        content: ShareCardPreview.content(oshi: Oshi(name: "ソラ", color: .mint)),
        style: ShareCardStyle(theme: .shipping, background: .photo(fileName: "\(UUID().uuidString).jpg")),
        images: ShareCardImages(background: photo)
    )
}
