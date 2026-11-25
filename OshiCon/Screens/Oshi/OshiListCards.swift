//
//  OshiListCards.swift
//  OshiCon
//

import SwiftUI

// 推しの一覧（`OshiListScreen`）のふつうの一覧に並べる、1 位の推しのカードと 2 位からの推しの行。
// 押したときの動き（編集を開く）と読み上げは、置く側（`OshiListScreen`）がボタンに付ける。

/// 1 位の推しのカード。チェキの写真の右に、「最推し！」のリボンと「テーマカラー」、名前、次の予定のタイトル、残り日数、予定の件数を出す。
/// とても大きな文字では、チェキを上に、文字を下に並べる。
struct OshiTopCard: View {
    /// チェキの枠の幅。
    private static let chekiWidth: CGFloat = 92
    /// チェキの傾き（度）。
    private static let chekiTilt: Double = -4

    let row: OshiListContent.Row

    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
        layout {
            OshiChekiPhoto(oshi: row.oshi, width: Self.chekiWidth, tilt: Self.chekiTilt)
            details
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(theme.palette.surface.color, in: RoundedRectangle(cornerRadius: theme.shape.section))
        .themeCardBorder(RoundedRectangle(cornerRadius: theme.shape.section))
        .contentShape(RoundedRectangle(cornerRadius: theme.shape.section))
        .accessibilityElement(children: .combine)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    topRibbon
                    themeColorNote
                }
                VStack(alignment: .leading, spacing: 4) {
                    topRibbon
                    themeColorNote
                }
            }
            Text(row.oshi.name)
                .font(theme.typography.text(.title3, weight: .bold))
                .foregroundStyle(theme.palette.onSurface.color)
                .lineLimit(2)
            if let nextEvent = row.nextEvent {
                Text(nextEvent.event.title)
                    .font(theme.typography.text(.footnote))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    .lineLimit(2)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        countdown(nextEvent)
                        Spacer(minLength: 0)
                        eventCount
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        countdown(nextEvent)
                        eventCount
                    }
                }
            } else {
                eventCount
            }
        }
    }

    /// 「最推し！」のリボン。順位の数字は出さず、いちばん上の推し（並べ替えの間の 1 位）だと伝える。
    private var topRibbon: some View {
        RibbonLabel(title: Text("最推し！"), systemImage: "crown.fill", textStyle: .footnote)
    }

    /// 1 位の推しの推し色がアプリの色（テーマ）になっていることの添え書き。
    private var themeColorNote: some View {
        Text("テーマカラー")
            .font(theme.typography.text(.caption))
            .foregroundStyle(theme.palette.onSurfaceVariant.color)
            .lineLimit(1)
    }

    private var eventCount: some View {
        Text(row.eventCountText)
            .font(theme.typography.text(.footnote))
            .foregroundStyle(theme.palette.onSurfaceVariant.color)
            .lineLimit(1)
    }

    private func countdown(_ nextEvent: ScheduledEvent) -> some View {
        DaysCountdownView(
            scheduled: nextEvent,
            color: row.oshi.color.text(in: theme).color,
            mutedColor: theme.palette.onSurfaceVariant.color,
            numberFont: theme.typography.countdownClock,
            unitFont: theme.typography.text(.subheadline, weight: .bold),
            showsPrefix: true,
            todayPillColor: row.oshi.color
        )
    }
}

/// 2 位からの推しの行。缶バッジのアバター・名前・次の予定のタイトルと日付（`5th LIVE · 10月25日(日)`）と、右に残り日数を推し色で出す（当日は「今日！」の札）。
/// これからの予定が無い推しは、名前の下に予定の件数を出し、残り日数は出さない。
struct OshiNextEventRow: View {
    /// アバターの一辺。
    private static let avatarSize: CGFloat = 48

    let row: OshiListContent.Row

    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            OshiPhotoAvatar(oshi: row.oshi, size: Self.avatarSize)
                .canBadgeStyle(color: row.oshi.color, size: Self.avatarSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.oshi.name)
                    .font(theme.typography.text(.body, weight: .bold))
                    .foregroundStyle(theme.palette.onSurface.color)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                supportingText
                    .font(theme.typography.text(.footnote))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
            }
            // 次の予定のタイトルをできるだけ長く出せるよう、間は行の間隔だけにする
            Spacer(minLength: 0)
            if let nextEvent = row.nextEvent {
                DaysCountdownView(
                    scheduled: nextEvent,
                    color: row.oshi.color.text(in: theme).color,
                    mutedColor: theme.palette.onSurfaceVariant.color,
                    numberFont: theme.typography.countdownSmall,
                    unitFont: theme.typography.text(.caption, weight: .bold),
                    showsPrefix: false,
                    todayPillColor: row.oshi.color
                )
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// 名前の下の補足。次の予定があれば「タイトル · 日付」、無ければ予定の件数。
    /// タイトルが長くて 1 行に収まらないときは、日付を残してタイトルを切り詰める。
    /// とても大きな文字では 1 行に並べると両方が切れるので、タイトルと日付を 2 段に分ける。
    @ViewBuilder private var supportingText: some View {
        if let nextEvent = row.nextEvent, let date = row.nextEventDateText {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    Text(nextEvent.event.title)
                        .lineLimit(2)
                    Text(date)
                        .lineLimit(1)
                }
            } else {
                HStack(spacing: 0) {
                    Text(nextEvent.event.title)
                        .lineLimit(1)
                    Text(verbatim: " · \(date)")
                        .lineLimit(1)
                        .layoutPriority(1)
                }
            }
        } else {
            Text(row.eventCountText)
                .lineLimit(1)
        }
    }
}

#Preview {
    let today = CalendarDay(Date(), calendar: .current)
    let lumina = Oshi(name: "LUMINA", color: .pink)
    let minato = Oshi(name: "ミナト", color: .navy)
    let leo = Oshi(name: "レオ", color: .red)
    let content = OshiListContent(
        oshis: [lumina, minato, leo],
        events: [
            OshiEvent(oshiID: lumina.id, kind: .live, title: "ドームツアー 東京公演", day: today.adding(days: 12), createdAt: Date()),
            OshiEvent(oshiID: minato.id, kind: .birthday, title: "ミナトの誕生日", day: today, repeatsYearly: true, createdAt: Date())
        ],
        today: today
    )
    return VStack(spacing: 14) {
        if let top = content.top {
            OshiTopCard(row: top)
        }
        ForEach(content.others) { row in
            OshiNextEventRow(row: row)
        }
    }
    .padding()
}
