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

/// 先頭の予定のカード。推し色の塗りに白い文字で、残り日数を大きく出す。
struct FeaturedEventCard: View {
    let item: HomeContent.Item

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.featuredBadgeText)
                    .font(theme.typography.text(.caption, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2), in: Capsule())
                Spacer(minLength: 8)
                if let oshi = item.oshi {
                    Text(oshi.name)
                        .font(theme.typography.text(.subheadline, weight: .medium))
                        .lineLimit(1)
                }
            }
            Text(item.event.title)
                .font(theme.typography.text(.title2, weight: .bold))
                .lineLimit(2)
            DaysCountdownView(
                scheduled: item.scheduled,
                color: item.color.onFill,
                mutedColor: item.color.onFill,
                // 横向きの iPhone（縦が狭い）では、カードで画面が埋まらないよう数字を小さくする
                numberFont: verticalSizeClass == .compact ? theme.typography.countdownClock : theme.typography.countdownLarge,
                unitFont: theme.typography.text(.title3, weight: .bold),
                showsPrefix: true,
                oshiColor: item.color
            )
            HStack(spacing: 12) {
                Text(EventText.dateBadge(item.scheduled.occurrenceDay, locale: item.locale))
                    .font(theme.typography.dateBadge)
                if let startTime = item.event.startTime {
                    Text(EventText.startTime(startTime, kind: item.event.kind, locale: item.locale))
                        .font(theme.typography.text(.subheadline, weight: .medium))
                }
            }
        }
        .foregroundStyle(item.color.onFill)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(item.color.fill, in: RoundedRectangle(cornerRadius: theme.shape.heroCard))
        .themeCardBorder(RoundedRectangle(cornerRadius: theme.shape.heroCard))
        .contentShape(RoundedRectangle(cornerRadius: theme.shape.heroCard))
    }
}

/// ホームの予定の行。アバター・タイトル・補足と、右に残り日数を推し色で出す。
struct HomeEventRow: View {
    let item: HomeContent.Item

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            if let oshi = item.oshi {
                OshiPhotoAvatar(oshi: oshi, size: 44)
            } else {
                OshiAvatar(name: item.event.title, color: item.color, size: 44)
            }
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
                oshiColor: item.color
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

/// 残り日数。これからは数字と「日」（先頭のカードは「あと N 日」）、当日は「今日！」、終わった予定は「N 日前」。
/// 数字の前後の文言は言語で変わる（en は `3 days`・`3 days left`）。
struct DaysCountdownView: View {
    let scheduled: ScheduledEvent
    let color: Color
    let mutedColor: Color
    let numberFont: Font
    let unitFont: Font
    let showsPrefix: Bool
    /// 数字の効果（テーマの装飾）に使う推し色。
    let oshiColor: OshiColor

    @Environment(\.appTheme) private var theme

    var body: some View {
        switch scheduled.status {
        case .today:
            Text("今日！")
                .font(unitFont)
                .foregroundStyle(color)
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
                    .themeNumeralEffect(oshiColor)
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
