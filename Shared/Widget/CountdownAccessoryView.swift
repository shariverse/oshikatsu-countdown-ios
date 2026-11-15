//
//  CountdownAccessoryView.swift
//  OshiCon
//

import SwiftUI
import WidgetKit

/// カウントダウンウィジェットのロック画面の形（丸・長方形・1 行）。選んだ予定 1 件の「あと N 日」を出す。
///
/// ロック画面は端末が単色（壁紙に合わせた色）で描くので、推し色の塗りとテーマの装飾は使わない。書体はテーマのもの。
/// 押すとアプリで予定の詳細を開く（ホーム画面の 2×2 と同じ）。
/// 形は引数で受ける（`widgetFamily` は Environment に入れられないので、アプリの Preview でも形を選べるように）。
struct CountdownAccessoryView: View {
    /// ロック画面の形。
    enum Family: CaseIterable {
        case circular
        case rectangular
        case inline
    }

    let content: CountdownWidgetContent
    let family: Family

    @Environment(\.appTheme) private var theme

    var body: some View {
        Group {
            switch family {
            case .circular:
                circular
            case .rectangular:
                rectangular
            case .inline:
                inline
            }
        }
        .widgetURL(link.url)
        .containerBackground(for: .widget) {
            if family == .circular {
                AccessoryWidgetBackground()
            }
        }
        .environment(\.locale, .app)
    }

    private var link: WidgetLink {
        if case let .event(event) = content {
            .eventDetail(event.eventID)
        } else {
            .home
        }
    }

    // MARK: - 丸

    /// 丸: 残り日数の数字と、登録した日から開始までの進み具合の輪。当日は「今日！」。
    @ViewBuilder private var circular: some View {
        switch content {
        case let .event(event):
            // ゲージのラベルに入れるとシステムが文字を小さくするので、輪の上に重ねる
            ZStack {
                Gauge(value: event.progress ?? 0) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .widgetAccentable()
                circularLabel(event)
                    .padding(8)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(event.accessibilityLabel)
        case .notSelected, .missing, .unavailable:
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title2)
                .accessibilityLabel(messageTitle)
        }
    }

    @ViewBuilder private func circularLabel(_ event: CountdownWidgetContent.Event) -> some View {
        switch event.status {
        case .upcoming:
            let parts = event.dayCountParts
            VStack(spacing: -2) {
                Text(parts.number)
                    .font(theme.typography.numeral(size: 24, relativeTo: .title2))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if !parts.suffix.isEmpty {
                    Text(parts.suffix)
                        .font(theme.typography.text(.caption2, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        case .today:
            Text(EventText.today(locale: event.locale))
                .font(theme.typography.text(.caption, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        case .ended:
            Text(event.countdownText)
                .font(theme.typography.text(.caption2, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
        }
    }

    // MARK: - 長方形

    /// 長方形: 推しの名前（推しなしの予定は種類）・タイトル・残り日数。
    @ViewBuilder private var rectangular: some View {
        switch content {
        case let .event(event):
            VStack(alignment: .leading, spacing: 0) {
                Text(event.heading)
                    .font(theme.typography.text(.caption, weight: .bold))
                    .lineLimit(1)
                    .widgetAccentable()
                Text(event.title)
                    .font(theme.typography.text(.headline, weight: .bold))
                    .lineLimit(1)
                Text(event.countdownText)
                    .font(theme.typography.text(.body))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(event.accessibilityLabel)
        case .notSelected, .missing, .unavailable:
            Text(messageTitle)
                .font(theme.typography.text(.headline, weight: .bold))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 1 行

    /// 1 行: 残り日数とタイトル。端末が後ろを切り詰めるので、残り日数を先に出す。
    @ViewBuilder private var inline: some View {
        switch content {
        case let .event(event):
            Text(event.inlineText)
                .accessibilityLabel(event.accessibilityLabel)
        case .notSelected, .missing, .unavailable:
            Text(messageTitle)
        }
    }

    // MARK: - 案内

    /// 予定を出せないときの短い案内（ホーム画面の 2×2 の見出しと同じ文言）。
    private var messageTitle: LocalizedStringKey {
        switch content {
        case .event, .notSelected:
            "予定を選んでください"
        case .missing:
            "予定が見つかりません"
        case .unavailable:
            "データを読み込めませんでした"
        }
    }
}
