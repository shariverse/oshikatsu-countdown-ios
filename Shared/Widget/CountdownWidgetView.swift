//
//  CountdownWidgetView.swift
//  OshiCon
//

import SwiftUI
import WidgetKit

/// カウントダウンウィジェット（2×2）の中身。選んだ予定 1 件を、推し色の塗りに白い文字で「あと N 日」と出す。
/// アプリの Preview からもウィジェットの大きさの枠で描けるよう、Widget Extension ではなくここに置く。
struct CountdownWidgetView: View {
    let content: CountdownWidgetContent

    @Environment(\.appTheme) private var theme

    var body: some View {
        Group {
            switch content {
            case let .event(event):
                EventCountdownView(event: event)
                    .widgetURL(WidgetLink.eventDetail(event.eventID).url)
            case .notSelected:
                message(title: "予定を選んでください", detail: "長押しして「ウィジェットを編集」から選びます")
            case .missing:
                message(title: "予定が見つかりません", detail: "長押しして「ウィジェットを編集」から選び直します")
            case .unavailable:
                message(title: "データを読み込めませんでした", detail: "しばらくしてからもう一度表示します")
            }
        }
        .containerBackground(Self.containerColor(for: content, in: theme), for: .widget)
        .environment(\.locale, .app)
    }

    /// ウィジェットの地。予定は推し色の塗り、ほかはカードの地。
    static func containerColor(for content: CountdownWidgetContent, in theme: AppTheme) -> Color {
        switch content {
        case let .event(event):
            event.color.fill
        case .notSelected, .missing, .unavailable:
            theme.palette.surface.color
        }
    }

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
        .widgetURL(WidgetLink.home.url)
    }
}

/// 選んだ予定。上に推しの名前（推しなしは種類）とタイトル、下に残り日数を大きく出す。
private struct EventCountdownView: View {
    let event: CountdownWidgetContent.Event

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.heading)
                .font(theme.typography.text(.caption, weight: .bold))
                .lineLimit(1)
                .opacity(0.9)
            Text(event.title)
                .font(theme.typography.text(.subheadline, weight: .bold))
                .lineLimit(2)
            Spacer(minLength: 4)
            countdown
        }
        .foregroundStyle(event.color.onFill)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(event.accessibilityLabel)
    }

    @ViewBuilder private var countdown: some View {
        switch event.status {
        case .upcoming:
            // 桁が多いときは数字を小さくして 1 行に収める
            let parts = event.countdownParts
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if !parts.prefix.isEmpty {
                    Text(parts.prefix)
                        .font(theme.typography.text(.caption, weight: .bold))
                        .lineLimit(1)
                }
                Text(parts.number)
                    .font(theme.typography.numeral(size: 48, relativeTo: .largeTitle))
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
            Text("今日！")
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
}
