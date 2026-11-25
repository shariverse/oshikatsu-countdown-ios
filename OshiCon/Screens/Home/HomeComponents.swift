//
//  HomeComponents.swift
//  OshiCon
//

import SwiftUI

/// 推しの絞り込み。「すべて」と推しごとのボタンを横に並べる。読み上げでは選んでいるかを伝える。
struct OshiFilterBar: View {
    let oshis: [Oshi]
    @Binding var selection: Oshi.ID?

    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: String(localized: "すべて"), color: nil, isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(oshis) { oshi in
                    chip(title: oshi.name, color: oshi.color, isSelected: selection == oshi.id) {
                        selection = oshi.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("推しで絞り込む")
    }

    private func chip(title: String, color: OshiColor?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let color {
                    OshiColorDot(color: color)
                }
                Text(title)
                    .font(theme.typography.text(.subheadline, weight: isSelected ? .bold : .regular))
                    .lineLimit(1)
            }
            .foregroundStyle(theme.palette.onSurface.color)
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .background(
                (isSelected ? (color?.container(in: theme) ?? theme.palette.brandContainer) : theme.palette.surface).color,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : theme.palette.outlineVariant.color)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// 先頭の予定のカード。推し色の塗りに白い文字のチケットで、残り日数を大きく出す。
///
/// 左右に半円の切り欠きを入れ、点線のミシン目で本体と半券に分ける（`TicketShape`）。
/// 本体は札（「ピン留め」か「いちばん近い予定」・予定の種類）・推しの名前・タイトル・残り日数で、写真のある推しはチェキ風の写真を右に載せる。
/// 半券は日付・開始の時刻・会場。切り欠き・ミシン目・チェキは飾りで、読み上げは置く側がカード全体に付ける。
struct FeaturedEventCard: View {
    /// チェキの枠の幅。
    private static let chekiWidth: CGFloat = 84
    /// 横向きの iPhone（縦が狭い）でのチェキの枠の幅。カードで画面が埋まらないよう小さくする。
    private static let compactChekiWidth: CGFloat = 60
    /// チェキの傾き（度）。
    private static let chekiTilt: Double = 5
    /// 中身の左右の余白。二重の線と切り欠きにかからない幅にする。
    private static let horizontalPadding: CGFloat = 18

    let item: HomeContent.Item

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.appTheme) private var theme
    /// 半券の高さ。切り欠きの位置を、半券の上の端（ミシン目）に合わせる。
    @State private var stubHeight: CGFloat = 0

    var body: some View {
        let shape = TicketShape(cornerRadius: theme.shape.heroCard, stubHeight: stubHeight)
        VStack(alignment: .leading, spacing: 0) {
            main
                .padding(.horizontal, Self.horizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, 14)
            stub
                .padding(.horizontal, Self.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    perforation
                }
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    stubHeight = height
                }
        }
        .foregroundStyle(item.color.onFill)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(item.color.fill, in: shape)
        .themeCardBorder(shape)
        .contentShape(RoundedRectangle(cornerRadius: theme.shape.heroCard))
    }

    /// チェキを載せるか。写真のある推しの予定だけ。とても大きな文字では、タイトルと残り日数の幅を空けるため載せない。
    private var showsCheki: Bool {
        item.oshi?.photoFileName != nil && !dynamicTypeSize.isAccessibilitySize
    }

    /// 本体。札と推しの名前、タイトル、残り日数。右にチェキ。
    private var main: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.event.title)
                        .font(theme.typography.text(.title3, weight: .bold))
                        .lineLimit(2)
                    DaysCountdownView(
                        scheduled: item.scheduled,
                        color: item.color.onFill,
                        mutedColor: item.color.onFill,
                        // 横向きの iPhone（縦が狭い）では、カードで画面が埋まらないよう数字を小さくする
                        numberFont: verticalSizeClass == .compact ? theme.typography.countdownClock : theme.typography.countdownLarge,
                        unitFont: theme.typography.text(.title3, weight: .bold),
                        showsPrefix: true
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if showsCheki, let oshi = item.oshi {
                    OshiChekiPhoto(
                        oshi: oshi,
                        width: verticalSizeClass == .compact ? Self.compactChekiWidth : Self.chekiWidth,
                        tilt: Self.chekiTilt
                    )
                }
            }
        }
    }

    /// 札と推しの名前。1 行に収まらない言語・文字の大きさでは、推しの名前を下の行に、それでも収まらなければ札も 1 つずつ縦に並べる。
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                tags
                Spacer(minLength: 8)
                oshiName
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    tags
                }
                oshiName
            }
            VStack(alignment: .leading, spacing: 6) {
                tags
                oshiName
            }
        }
    }

    /// 「ピン留め」か「いちばん近い予定」の札と、予定の種類の札。
    @ViewBuilder private var tags: some View {
        TicketTag(text: item.featuredBadgeText, systemImage: item.event.isPinned ? "pin.fill" : nil)
        TicketTag(text: item.event.kind.label(locale: item.locale), systemImage: nil)
    }

    @ViewBuilder private var oshiName: some View {
        if let oshi = item.oshi {
            Text(oshi.name)
                .font(theme.typography.text(.subheadline, weight: .medium))
                .lineLimit(1)
        }
    }

    /// 半券。日付・開始の時刻・会場。1 行に収まらなければ会場を下の行に、それでも収まらなければ 1 つずつ縦に並べる。
    private var stub: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                dateAndTime
                Spacer(minLength: 8)
                venue
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    dateAndTime
                }
                venue
            }
            VStack(alignment: .leading, spacing: 4) {
                dateAndTime
                venue
            }
        }
    }

    @ViewBuilder private var dateAndTime: some View {
        Text(EventText.dateBadge(item.scheduled.occurrenceDay, locale: item.locale))
            .font(theme.typography.dateBadge)
            .lineLimit(1)
        if let startTime = item.event.startTime {
            Text(EventText.startTime(startTime, kind: item.event.kind, locale: item.locale))
                .font(theme.typography.text(.subheadline, weight: .medium))
                .lineLimit(1)
        }
    }

    @ViewBuilder private var venue: some View {
        if !item.event.venue.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.footnote)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .accessibilityHidden(true)
                Text(item.event.venue)
                    .font(theme.typography.text(.subheadline, weight: .medium))
                    .lineLimit(1)
            }
        }
    }

    /// ミシン目。半券の上の端に、切り欠きの間を結ぶ点線を引く。
    private var perforation: some View {
        TicketPerforation()
            .fill(item.color.onFill.opacity(0.6))
            .frame(height: TicketPerforation.lineWidth)
            .padding(.horizontal, Self.horizontalPadding)
            .offset(y: -TicketPerforation.lineWidth / 2)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

/// チケットの本体に置く小さな札（「ピン留め」・予定の種類）。推し色の塗りの上に、白を薄く重ねた地で置く。
private struct TicketTag: View {
    let text: String
    let systemImage: String?

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(theme.typography.text(.caption, weight: .bold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.white.opacity(0.2), in: Capsule())
    }
}

/// ホームの予定の行。缶バッジ風のアバター・タイトル・補足と、右に残り日数を推し色で出す（当日は「今日！」の札）。
struct HomeEventRow: View {
    /// アバターの一辺。
    private static let avatarSize: CGFloat = 44

    let item: HomeContent.Item

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            avatar
                .canBadgeStyle(color: item.color, size: Self.avatarSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.event.title)
                    .font(theme.typography.text(.body, weight: .bold))
                    .foregroundStyle(theme.palette.onSurface.color)
                    .lineLimit(1)
                Text(item.supportingText)
                    .font(theme.typography.text(.footnote))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            DaysCountdownView(
                scheduled: item.scheduled,
                color: item.color.text(in: theme).color,
                mutedColor: theme.palette.onSurfaceVariant.color,
                numberFont: theme.typography.countdownSmall,
                unitFont: theme.typography.text(.caption, weight: .bold),
                showsPrefix: false,
                todayPillColor: item.color
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var avatar: some View {
        if let oshi = item.oshi {
            OshiPhotoAvatar(oshi: oshi, size: Self.avatarSize)
        } else {
            OshiAvatar(name: item.event.title, color: item.color, size: Self.avatarSize)
        }
    }
}

/// 残り日数。これからは数字と「日」（先頭のカードは「あと N 日」）、当日は「今日！」、終わった予定は「N 日前」。
/// 数字の前後の文言は言語で変わる（en は `3 days`・`3 days left`）。
/// `todayPillColor` を渡すと、当日の「今日！」を推し色の札（`TodayPill`）で出す。
struct DaysCountdownView: View {
    let scheduled: ScheduledEvent
    let color: Color
    let mutedColor: Color
    let numberFont: Font
    let unitFont: Font
    let showsPrefix: Bool
    /// 当日の「今日！」を札で出すときの推し色。nil なら `color` の文字で出す（先頭のカード）。
    var todayPillColor: OshiColor?

    @Environment(\.appTheme) private var theme

    var body: some View {
        switch scheduled.status {
        case .today:
            if let todayPillColor {
                TodayPill(color: todayPillColor)
            } else {
                Text("今日！")
                    .font(unitFont)
                    .foregroundStyle(color)
            }
        case .ended:
            Text(EventText.countdown(daysUntil: scheduled.daysUntil, status: .ended))
                .font(theme.typography.text(.subheadline))
                .foregroundStyle(mutedColor)
        case .upcoming:
            let parts = EventText.countdownParts(days: scheduled.daysUntil, withPrefix: showsPrefix)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if !parts.prefix.isEmpty {
                    Text(parts.prefix)
                        .font(unitFont)
                }
                Text(parts.number)
                    .font(numberFont)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .countdownNumberTransition(scheduled.daysUntil)
                if !parts.suffix.isEmpty {
                    Text(parts.suffix)
                        .font(unitFont)
                }
            }
            .foregroundStyle(color)
        }
    }
}
