//
//  EventDetailCard.swift
//  OshiCon
//

import SwiftUI

/// 詳細の中身のカード。種類・推しの名前・タイトル、残り（または当日・終わった予定）、進み具合、日時・会場・くり返し。
/// 残りは `EventDetailCountdown`、進み具合のバーは `EventDetailProgressBar`、日時などの行は `EventDetailInfoRows` が描く。
struct EventDetailCard: View {
    let detail: EventDetailContent

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading
            EventDetailCountdown(detail: detail)
            if let progress = detail.countdown.progress,
               let percentText = detail.progressPercentText,
               let accessibilityLabel = detail.progressAccessibilityLabel {
                progressBar(progress: progress, percentText: percentText, accessibilityLabel: accessibilityLabel)
            }
            EventDetailInfoRows(rows: detail.infoRows)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            theme.palette.surface.color,
            in: UnevenRoundedRectangle(topLeadingRadius: theme.shape.detailCard, topTrailingRadius: theme.shape.detailCard)
        )
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(detail.kindLabel)
                    .font(theme.typography.text(.caption, weight: .bold))
                    .foregroundStyle(theme.palette.onSurface.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(detail.color.container(in: theme).color, in: RoundedRectangle(cornerRadius: theme.shape.tag))
                Text(detail.oshiName)
                    .font(theme.typography.text(.subheadline))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
            }
            Text(detail.event.title)
                .font(theme.typography.text(.title2, weight: .bold))
                .foregroundStyle(theme.palette.onSurface.color)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// 進み具合のバーと、両端と中央のラベル（登録の日・○% 経過・当日）。まとめて 1 つの要素として読む。
    private func progressBar(progress: Double, percentText: String, accessibilityLabel: String) -> some View {
        VStack(spacing: 6) {
            EventDetailProgressBar(progress: progress, tint: detail.color.text(in: theme).color)
            HStack {
                Text(detail.progressStartText)
                Spacer()
                Text(percentText)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.palette.onSurface.color)
                Spacer()
                Text(detail.progressEndText)
            }
            .font(theme.typography.text(.caption))
            .foregroundStyle(theme.palette.onSurfaceVariant.color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

#if DEBUG
/// Preview の見本。2026/10/6 に見た、東京ドームのライブ（開演 17:00）。`hour` は見ている時刻。
private enum EventDetailCardPreview {
    static func detail(daysAhead: Int, hour: Int = 9) -> EventDetailContent {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let today = CalendarDay(year: 2026, month: 10, day: 6)
        let now = today.date(at: TimeOfDay(hour: hour, minute: 18), calendar: calendar)
        let oshi = Oshi(name: "LUMINA", color: .pink)
        let event = OshiEvent(
            oshiID: oshi.id,
            kind: .live,
            title: "ドームツアー 東京公演",
            day: today.adding(days: daysAhead),
            startTime: TimeOfDay(hour: 17, minute: 0),
            venue: "東京ドーム",
            createdAt: now.addingTimeInterval(-36 * 86_400)
        )
        return EventDetailContent(event: event, oshi: oshi, now: now, calendar: calendar)
    }
}

#Preview("12 日前") {
    ScrollView {
        EventDetailCard(detail: EventDetailCardPreview.detail(daysAhead: 12))
    }
}

#Preview("当日の開始の前（ダーク）") {
    ScrollView {
        EventDetailCard(detail: EventDetailCardPreview.detail(daysAhead: 0))
    }
    .preferredColorScheme(.dark)
}

#Preview("開始を過ぎた当日") {
    ScrollView {
        EventDetailCard(detail: EventDetailCardPreview.detail(daysAhead: 0, hour: 18))
    }
}

#Preview("アクセシビリティの大きな文字") {
    ScrollView {
        EventDetailCard(detail: EventDetailCardPreview.detail(daysAhead: 12))
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
