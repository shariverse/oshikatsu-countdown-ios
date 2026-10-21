//
//  UpcomingWidget.swift
//  OshiConWidget
//

import SwiftUI
import WidgetKit

/// 推しカウントウィジェット（4×2）。当日とこれからの予定を近い順に、推し色の丸・タイトル・残り日数で並べる。
/// 行を押すとアプリで予定の詳細、右上の ＋ で予定の追加、見出しでアプリを開く。0:00 ごとのエントリで数え直す。
struct UpcomingWidget: Widget {
    static let kind = "jp.shilokuma.OshiCon.Upcoming"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: UpcomingProvider()) { entry in
            // 設定の「デバッグ」で選んだテーマ（DebugTheme。確認用のブランチだけ）
            UpcomingWidgetView(content: entry.content)
                .environment(\.appTheme, DebugTheme.storedTheme())
        }
        .configurationDisplayName("推しカウント")
        .description("これからの予定を近い順に表示します")
        .supportedFamilies([.systemMedium])
    }
}

nonisolated struct UpcomingEntry: TimelineEntry {
    /// 4×2 に収まる行の数。
    static let maxRows = UpcomingWidgetContent.maxRows

    let date: Date
    let content: UpcomingWidgetContent

    /// ウィジェットの一覧に出す見本。
    static var sample: Self {
        Self(date: .now, content: .sample)
    }
}

nonisolated struct UpcomingProvider: TimelineProvider {
    /// 先に作っておく 0:00 のエントリの数。使い切ったら作り直す。
    private static let midnightCount = 7
    /// ストアを読めなかったとき、読み直すまでの間隔。
    private static let retryInterval: TimeInterval = 15 * 60

    func placeholder(in context: Context) -> UpcomingEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (UpcomingEntry) -> Void) {
        if context.isPreview {
            completion(.sample)
            return
        }
        Task {
            let data = await WidgetStore.load()
            completion(Self.entry(at: .now, data: data, calendar: .autoupdatingCurrent))
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<UpcomingEntry>) -> Void) {
        Task {
            let now = Date.now
            guard let data = await WidgetStore.load() else {
                // 読めないことを「これからの予定はありません」と出し続けないよう、しばらくしてから読み直す
                completion(Timeline(
                    entries: [UpcomingEntry(date: now, content: .unavailable)],
                    policy: .after(now.addingTimeInterval(Self.retryInterval))
                ))
                return
            }
            let calendar = Calendar.autoupdatingCurrent
            let dates = [now] + WidgetTimeline.nextMidnights(after: now, count: Self.midnightCount, calendar: calendar)
            completion(Timeline(entries: dates.map { Self.entry(at: $0, data: data, calendar: calendar) }, policy: .atEnd))
        }
    }

    private static func entry(at date: Date, data: WidgetData?, calendar: Calendar) -> UpcomingEntry {
        guard let data else {
            return UpcomingEntry(date: date, content: .unavailable)
        }
        return UpcomingEntry(
            date: date,
            content: UpcomingWidgetContent(
                events: data.events,
                oshis: data.oshis,
                today: CalendarDay(date, calendar: calendar),
                maxRows: UpcomingEntry.maxRows
            )
        )
    }
}

#Preview(as: .systemMedium) {
    UpcomingWidget()
} timeline: {
    UpcomingEntry.sample
    UpcomingEntry(date: .now, content: .rows([]))
    UpcomingEntry(date: .now, content: .unavailable)
}
