//
//  EventLiveActivity.swift
//  OshiConWidget
//

import ActivityKit
import SwiftUI
import WidgetKit

/// 当日の開演までのライブアクティビティ（ロック画面と Dynamic Island）。中身はアプリが作る（`LiveActivityScheduler`）。
/// 押すとアプリで予定の詳細を開く。
struct EventLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EventActivityAttributes.self) { context in
            EventLiveActivityView(attributes: context.attributes, isStale: context.isStale)
                .activityBackgroundTint(context.attributes.color.rgb.color)
                .activitySystemActionForegroundColor(context.attributes.color.onFill)
                .widgetURL(context.attributes.link.url)
                .environment(\.locale, .app)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.heading)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "heart.fill")
                    }
                    .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // Dynamic Island の書体はシステムのもの（ロック画面はテーマの書体）
                    EventLiveActivityCountdown(
                        attributes: context.attributes,
                        isStale: context.isStale,
                        numeralSize: 24,
                        usesSystemTypeface: true
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.attributes.startText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "heart.fill")
                    .accessibilityLabel(context.attributes.heading)
            } compactTrailing: {
                if context.isStale {
                    Text(context.attributes.startedText)
                        .font(.caption2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: 64)
                } else {
                    EventLiveActivityTimer(attributes: context.attributes)
                        .font(.caption.bold())
                        .frame(maxWidth: 64)
                }
            } minimal: {
                Image(systemName: "heart.fill")
                    .accessibilityLabel(context.attributes.title)
            }
            .widgetURL(context.attributes.link.url)
            .keylineTint(context.attributes.color.rgb.color)
        }
    }
}

#Preview("ロック画面", as: .content, using: EventActivityAttributes.sample) {
    EventLiveActivity()
} contentStates: {
    EventActivityAttributes.ContentState()
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: EventActivityAttributes.sample) {
    EventLiveActivity()
} contentStates: {
    EventActivityAttributes.ContentState()
}
