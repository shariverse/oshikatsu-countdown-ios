//
//  EventLiveActivityView.swift
//  OshiCon
//

import SwiftUI
import WidgetKit

/// 当日のライブアクティビティのロック画面（と通知のバナー）の見た目。推し色の地に白い文字（ホーム画面のカウントダウンと同じ）。
/// 地の推し色は Widget Extension が `activityBackgroundTint` で塗る。アプリの Preview からも描けるよう、ここに置く。
struct EventLiveActivityView: View {
    let attributes: EventActivityAttributes
    /// 開演を過ぎて古くなった。
    let isStale: Bool

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.heading)
                    .font(theme.typography.text(.caption, weight: .bold))
                    .lineLimit(1)
                    .opacity(0.9)
                Text(attributes.title)
                    .font(theme.typography.text(.headline, weight: .bold))
                    .lineLimit(2)
                Text(attributes.startText)
                    .font(theme.typography.text(.caption))
                    .lineLimit(1)
                    .opacity(0.9)
            }
            Spacer(minLength: 0)
            EventLiveActivityCountdown(attributes: attributes, isStale: isStale, numeralSize: 34)
        }
        .foregroundStyle(attributes.color.onFill)
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

/// 残りの時間（`開演まで 1:23:45`）。開演を過ぎたら「今日は当日！」。
/// 書体は、ロック画面ではテーマのもの、Dynamic Island ではシステムのもの（`usesSystemTypeface`）。
struct EventLiveActivityCountdown: View {
    let attributes: EventActivityAttributes
    let isStale: Bool
    var numeralSize: CGFloat = 28
    /// システムの書体で描く（Dynamic Island）。false ならテーマの書体（ロック画面）。
    var usesSystemTypeface = false

    @Environment(\.appTheme) private var theme
    /// システムの書体の数字も、テーマの数字（`relativeTo: .title`）と同じく文字の大きさの設定に合わせる。
    @ScaledMetric(relativeTo: .title) private var numeralScale: CGFloat = 1

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if isStale {
                Text(attributes.startedText)
                    .font(textFont(.headline))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text(attributes.untilText)
                    .font(textFont(.caption))
                    .lineLimit(1)
                EventLiveActivityTimer(attributes: attributes)
                    .font(numeralFont)
            }
        }
    }

    private func textFont(_ style: Font.TextStyle) -> Font {
        usesSystemTypeface ? .system(style, weight: .bold) : theme.typography.text(style, weight: .bold)
    }

    private var numeralFont: Font {
        usesSystemTypeface
            ? .system(size: numeralSize * numeralScale, weight: .bold).monospacedDigit()
            : theme.typography.numeral(size: numeralSize, relativeTo: .title)
    }
}

/// 開演までの残り（時:分:秒）。端末が 1 秒ごとに数え、開演で 0:00 のまま止まる。
struct EventLiveActivityTimer: View {
    let attributes: EventActivityAttributes

    var body: some View {
        Text(timerInterval: attributes.countdownBegin...attributes.startDate, countsDown: true)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .lineLimit(1)
    }
}
