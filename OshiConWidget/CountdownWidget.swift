//
//  CountdownWidget.swift
//  OshiConWidget
//

import SwiftUI
import WidgetKit

/// カウントダウンウィジェット（2×2）。選んだ予定 1 件を、推し色の塗りに白い文字で「あと N 日」と出す。
/// 押すとアプリで予定の詳細を開く。0:00 ごとのエントリで、日付が変わったら数え直す。
struct CountdownWidget: Widget {
    static let kind = "jp.shilokuma.OshiCon.Countdown"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: SelectEventIntent.self, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("カウントダウン")
        .description("選んだ予定まであと何日かを数えます。")
        .supportedFamilies([.systemSmall])
    }
}

nonisolated struct CountdownEntry: TimelineEntry {
    let date: Date
    let content: CountdownWidgetContent

    /// ウィジェットの一覧に出す見本。
    static var sample: Self {
        let oshi = Oshi(name: "LUMINA", color: .pink)
        let today = CalendarDay(.now, calendar: .autoupdatingCurrent)
        let event = OshiEvent(
            oshiID: oshi.id,
            kind: .live,
            title: "5th LIVE 東京公演",
            day: CalendarDay(Date.now.addingTimeInterval(86_400 * 11), calendar: .autoupdatingCurrent),
            createdAt: .now
        )
        return Self(date: .now, content: .event(.init(event: event, oshi: oshi, today: today)))
    }
}

nonisolated struct CountdownProvider: AppIntentTimelineProvider {
    /// 先に作っておく 0:00 のエントリの数。使い切ったら作り直す。
    private static let midnightCount = 7

    func placeholder(in context: Context) -> CountdownEntry {
        .sample
    }

    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> CountdownEntry {
        // ウィジェットの一覧では見本を出す
        if context.isPreview, configuration.event == nil {
            return .sample
        }
        let data = await WidgetStore.load()
        return entry(at: .now, configuration: configuration, data: data, calendar: .autoupdatingCurrent)
    }

    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let data = await WidgetStore.load()
        let now = Date.now
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
                today: CalendarDay(date, calendar: calendar)
            )
        )
    }
}

struct CountdownWidgetView: View {
    let entry: CountdownEntry

    var body: some View {
        Group {
            switch entry.content {
            case let .event(event):
                EventCountdownView(event: event)
                    .widgetURL(WidgetLink.eventDetail(event.eventID).url)
                    .containerBackground(event.color.fill, for: .widget)
            case .notSelected:
                message(title: "予定を選んでください", detail: "長押しして「ウィジェットを編集」から選びます")
            case .missing:
                message(title: "予定が見つかりません", detail: "長押しして「ウィジェットを編集」から選び直します")
            }
        }
        .environment(\.locale, .app)
    }

    private func message(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.text(.subheadline, weight: .bold))
                .foregroundStyle(AppPalette.onSurface.color)
            Text(detail)
                .font(AppFont.text(.caption))
                .foregroundStyle(AppPalette.onSurfaceVariant.color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetLink.home.url)
        .containerBackground(AppPalette.surface.color, for: .widget)
    }
}

/// 選んだ予定。上に推しの名前（推しなしは種類）とタイトル、下に残り日数を大きく出す。
private struct EventCountdownView: View {
    let event: CountdownWidgetContent.Event

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.heading)
                .font(AppFont.text(.caption, weight: .bold))
                .lineLimit(1)
                .opacity(0.9)
            Text(event.title)
                .font(AppFont.text(.subheadline, weight: .bold))
                .lineLimit(2)
            Spacer(minLength: 4)
            countdown
        }
        .foregroundStyle(event.color.onFill)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.heading)、\(event.title)、\(event.countdownText)")
    }

    @ViewBuilder private var countdown: some View {
        switch event.status {
        case .upcoming:
            // 桁が多いときは数字を小さくして 1 行に収める
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("あと")
                    .font(AppFont.text(.caption, weight: .bold))
                Text("\(event.daysUntil)")
                    .font(AppFont.numeral(size: 48, relativeTo: .largeTitle))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                Text("日")
                    .font(AppFont.text(.caption, weight: .bold))
            }
        case .today:
            Text("今日！")
                .font(AppFont.text(.title, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        case .ended:
            Text(event.countdownText)
                .font(AppFont.text(.title3, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

#Preview(as: .systemSmall) {
    CountdownWidget()
} timeline: {
    CountdownEntry.sample
    CountdownEntry(date: .now, content: .notSelected)
    CountdownEntry(date: .now, content: .missing)
}
