//
//  CountdownWidget.swift
//  OshiConWidget
//

import SwiftUI
import WidgetKit

/// カウントダウンウィジェット。選んだ予定 1 件の「あと N 日」を出す。
/// ホーム画面（2×2）は推し色の塗りに白い文字、ロック画面（丸・長方形・1 行）は端末が単色で描く。
/// 押すとアプリで予定の詳細を開く。0:00 ごとのエントリで、日付が変わったら数え直す。
struct CountdownWidget: Widget {
    static let kind = "jp.shilokuma.OshiCon.Countdown"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: SelectEventIntent.self, provider: CountdownProvider()) { entry in
            CountdownWidgetEntryView(content: entry.content)
                .environment(\.appTheme, .shipping(themeColor: entry.themeColor))
        }
        .configurationDisplayName("カウントダウン")
        .description("選んだ予定まであと何日かを推し色で表示します")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

/// ホーム画面の 2×2 とロック画面の形で、中身の描き方を分ける。
private struct CountdownWidgetEntryView: View {
    let content: CountdownWidgetContent

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CountdownAccessoryView(content: content, family: .circular)
        case .accessoryRectangular:
            CountdownAccessoryView(content: content, family: .rectangular)
        case .accessoryInline:
            CountdownAccessoryView(content: content, family: .inline)
        default:
            CountdownWidgetView(content: content)
        }
    }
}

nonisolated struct CountdownEntry: TimelineEntry {
    let date: Date
    let content: CountdownWidgetContent
    /// テーマを染める色（1 位の推しの推し色）。見本・読めないときは nil（ピンクのまま）。
    var themeColor: OshiColor?

    /// ウィジェットの一覧に出す見本。
    static var sample: Self {
        Self(date: .now, content: .sample)
    }
}

nonisolated struct CountdownProvider: AppIntentTimelineProvider {
    /// 先に作っておく 0:00 のエントリの数。使い切ったら作り直す。
    private static let midnightCount = 7
    /// ストアを読めなかったとき、読み直すまでの間隔。
    private static let retryInterval: TimeInterval = 15 * 60

    func placeholder(in context: Context) -> CountdownEntry {
        .sample
    }

    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> CountdownEntry {
        // ウィジェットの一覧では見本を出す
        if context.isPreview, configuration.event == nil {
            return .sample
        }
        guard let data = await WidgetStore.load() else {
            return CountdownEntry(date: .now, content: .unavailable)
        }
        return entry(at: .now, configuration: configuration, data: data, calendar: .autoupdatingCurrent)
    }

    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let now = Date.now
        guard let data = await WidgetStore.load() else {
            // 読めないことを「予定が見つかりません」と出し続けないよう、しばらくしてから読み直す
            return Timeline(
                entries: [CountdownEntry(date: now, content: .unavailable)],
                policy: .after(now.addingTimeInterval(Self.retryInterval))
            )
        }
        let calendar = Calendar.autoupdatingCurrent
        let dates = [now] + WidgetTimeline.nextMidnights(after: now, count: Self.midnightCount, calendar: calendar)
        let entries = dates.map { entry(at: $0, configuration: configuration, data: data, calendar: calendar) }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(at date: Date, configuration: SelectEventIntent, data: WidgetData, calendar: Calendar) -> CountdownEntry {
        CountdownEntry(
            date: date,
            content: CountdownWidgetContent(
                eventID: configuration.event?.id,
                events: data.events,
                oshis: data.oshis,
                now: date,
                calendar: calendar
            ),
            themeColor: data.themeColor
        )
    }
}

#Preview(as: .systemSmall) {
    CountdownWidget()
} timeline: {
    CountdownEntry.sample
    CountdownEntry(date: .now, content: .notSelected)
    CountdownEntry(date: .now, content: .missing)
    CountdownEntry(date: .now, content: .unavailable)
}

#Preview("ロック画面・丸", as: .accessoryCircular) {
    CountdownWidget()
} timeline: {
    CountdownEntry.sample
    CountdownEntry(date: .now, content: .notSelected)
}

#Preview("ロック画面・長方形", as: .accessoryRectangular) {
    CountdownWidget()
} timeline: {
    CountdownEntry.sample
    CountdownEntry(date: .now, content: .missing)
}

#Preview("ロック画面・1 行", as: .accessoryInline) {
    CountdownWidget()
} timeline: {
    CountdownEntry.sample
    CountdownEntry(date: .now, content: .notSelected)
}
