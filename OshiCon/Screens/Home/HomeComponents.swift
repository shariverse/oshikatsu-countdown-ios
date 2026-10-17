//
//  HomeComponents.swift
//  OshiCon
//

import SwiftUI

/// 推しの絞り込み。「すべて」と推しごとのボタンを横に並べる。読み上げでは選んでいるかを伝える。
struct OshiFilterBar: View {
    let oshis: [Oshi]
    @Binding var selection: Oshi.ID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "すべて", color: nil, isSelected: selection == nil) {
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
                    .font(AppFont.text(.subheadline, weight: isSelected ? .bold : .regular))
                    .lineLimit(1)
            }
            .foregroundStyle(AppPalette.onSurface.color)
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .background(
                (isSelected ? (color?.container ?? AppPalette.brandContainer) : AppPalette.surface).color,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : AppPalette.outlineVariant.color)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.event.isPinned ? "ピン留め" : "いちばん近い予定")
                    .font(AppFont.text(.caption, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2), in: Capsule())
                Spacer(minLength: 8)
                if let oshi = item.oshi {
                    Text(oshi.name)
                        .font(AppFont.text(.subheadline, weight: .medium))
                        .lineLimit(1)
                }
            }
            Text(item.event.title)
                .font(AppFont.text(.title2, weight: .bold))
                .lineLimit(2)
            DaysCountdownView(
                scheduled: item.scheduled,
                color: item.color.onFill,
                mutedColor: item.color.onFill,
                numberFont: AppFont.countdownLarge,
                unitFont: AppFont.text(.title3, weight: .bold),
                showsPrefix: true
            )
            HStack(spacing: 12) {
                Text(EventText.dateBadge(item.scheduled.occurrenceDay))
                    .font(AppFont.dateBadge)
                if let startTime = item.event.startTime {
                    Text(EventText.startTime(startTime, kind: item.event.kind))
                        .font(AppFont.text(.subheadline, weight: .medium))
                }
            }
        }
        .foregroundStyle(item.color.onFill)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(item.color.fill, in: RoundedRectangle(cornerRadius: 28))
        .contentShape(RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var parts = [item.event.isPinned ? "ピン留め" : "いちばん近い予定"]
        if let oshi = item.oshi {
            parts.append(oshi.name)
        }
        parts.append(item.event.title)
        parts.append(item.countdownText)
        parts.append(EventText.monthDayWeekday(item.scheduled.occurrenceDay))
        if let startTime = item.event.startTime {
            parts.append(EventText.startTime(startTime, kind: item.event.kind))
        }
        return parts.joined(separator: "、")
    }
}

/// ホームの予定の行。アバター・タイトル・補足と、右に残り日数を推し色で出す。
struct HomeEventRow: View {
    let item: HomeContent.Item

    var body: some View {
        HStack(spacing: 12) {
            if let oshi = item.oshi {
                OshiPhotoAvatar(oshi: oshi, size: 44)
            } else {
                OshiAvatar(name: item.event.title, color: item.color, size: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.event.title)
                    .font(AppFont.text(.body, weight: .bold))
                    .foregroundStyle(AppPalette.onSurface.color)
                    .lineLimit(1)
                Text(item.supportingText)
                    .font(AppFont.text(.footnote))
                    .foregroundStyle(AppPalette.onSurfaceVariant.color)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            DaysCountdownView(
                scheduled: item.scheduled,
                color: item.color.text.color,
                mutedColor: AppPalette.onSurfaceVariant.color,
                numberFont: AppFont.countdownSmall,
                unitFont: AppFont.text(.caption, weight: .bold),
                showsPrefix: false
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.event.title)、\(item.supportingText)、\(item.countdownText)")
        .accessibilityAddTraits(.isButton)
    }
}

/// 残り日数。これからは数字と「日」（先頭のカードは前に「あと」）、当日は「今日！」、終わった予定は「N 日前」。
struct DaysCountdownView: View {
    let scheduled: ScheduledEvent
    let color: Color
    let mutedColor: Color
    let numberFont: Font
    let unitFont: Font
    let showsPrefix: Bool

    var body: some View {
        switch scheduled.status {
        case .today:
            Text("今日！")
                .font(unitFont)
                .foregroundStyle(color)
        case .ended:
            Text(EventText.countdown(daysUntil: scheduled.daysUntil, status: .ended))
                .font(AppFont.text(.subheadline))
                .foregroundStyle(mutedColor)
        case .upcoming:
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if showsPrefix {
                    Text("あと")
                        .font(unitFont)
                }
                Text("\(scheduled.daysUntil)")
                    .font(numberFont)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("日")
                    .font(unitFont)
            }
            .foregroundStyle(color)
        }
    }
}
