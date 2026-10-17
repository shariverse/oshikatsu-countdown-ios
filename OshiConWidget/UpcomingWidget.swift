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
            UpcomingWidgetView(entry: entry)
        }
        .configurationDisplayName("推しカウント")
        .description("これからの予定を近い順に表示します")
        .supportedFamilies([.systemMedium])
    }
}

nonisolated struct UpcomingEntry: TimelineEntry {
    /// 4×2 に収まる行の数。
    static let maxRows = 4

    let date: Date
    let content: UpcomingWidgetContent

    /// ウィジェットの一覧に出す見本。
    static var sample: Self {
        let calendar = Calendar.autoupdatingCurrent
        let today = CalendarDay(.now, calendar: calendar)
        let day = { (days: Double) in CalendarDay(Date.now.addingTimeInterval(86_400 * days), calendar: calendar) }
        let lumina = Oshi(name: "LUMINA", color: .pink)
        let minato = Oshi(name: "ミナト", color: .navy)
        let sora = Oshi(name: "ソラ", color: .mint)
        let events = [
            OshiEvent(oshiID: minato.id, kind: .birthday, title: "ミナトの誕生日", day: today, createdAt: .now),
            OshiEvent(oshiID: lumina.id, kind: .live, title: "5th LIVE 東京公演", day: day(12), createdAt: .now),
            OshiEvent(oshiID: sora.id, kind: .release, title: "2nd シングル発売", day: day(25), createdAt: .now)
        ]
        let content = UpcomingWidgetContent(events: events, oshis: [lumina, minato, sora], today: today, maxRows: maxRows)
        return Self(date: .now, content: content)
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

struct UpcomingWidgetView: View {
    let entry: UpcomingEntry

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            switch entry.content {
            case let .rows(rows) where rows.isEmpty:
                message("これからの予定はありません")
            case let .rows(rows):
                // 端末や文字の大きさで高さが違うので、収まる件数まで減らす（4 → 3 → 2 → 1 件）
                ViewThatFits(in: .vertical) {
                    ForEach((1...rows.count).reversed(), id: \.self) { count in
                        rowList(Array(rows.prefix(count)))
                    }
                }
                Spacer(minLength: 0)
            case .unavailable:
                message("データを読み込めませんでした")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetLink.home.url)
        .containerBackground(AppPalette.surfaceContainer.color, for: .widget)
        .environment(\.locale, .app)
    }

    /// 見出し（押すとアプリ）と、右上の ＋（押すと予定の追加）。
    private var header: some View {
        HStack {
            Link(destination: WidgetLink.home.url) {
                Text("推しカウント")
                    .font(AppFont.text(.subheadline, weight: .bold))
                    .foregroundStyle(AppPalette.onSurface.color)
            }
            Spacer()
            Link(destination: WidgetLink.addEvent.url) {
                // 見た目は 32pt の丸、押せる範囲は 44pt にする
                addButtonLabel
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .padding(.trailing, -6)
            .padding(.vertical, -6)
            .accessibilityLabel("予定を追加")
        }
    }

    private func rowList(_ rows: [UpcomingWidgetContent.Row]) -> some View {
        VStack(spacing: 2) {
            ForEach(rows) { row in
                Link(destination: WidgetLink.eventDetail(row.id).url) {
                    UpcomingRowView(row: row)
                }
            }
        }
    }

    /// ＋ の丸。色付き・透明のウィジェット（色が 1 色になる描き方）では、塗りと記号が同じ色で見えなくなるので輪郭の丸にする。
    @ViewBuilder private var addButtonLabel: some View {
        let plus = Image(systemName: "plus")
            .font(.system(size: 15, weight: .bold))
            .frame(width: 32, height: 32)
        if renderingMode == .fullColor {
            plus
                .foregroundStyle(AppPalette.onBrand.color)
                .background(AppPalette.brand.color, in: Circle())
        } else {
            plus
                .overlay(Circle().strokeBorder(lineWidth: 2))
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(AppFont.text(.footnote))
            .foregroundStyle(AppPalette.onSurfaceVariant.color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 推しカウントの 1 行。推し色の丸・タイトル・残り日数（推し色。当日は「今日！」）。
private struct UpcomingRowView: View {
    let row: UpcomingWidgetContent.Row

    var body: some View {
        HStack(spacing: 8) {
            OshiColorDot(color: row.color)
            Text(row.title)
                .font(AppFont.text(.footnote, weight: .medium))
                .foregroundStyle(AppPalette.onSurface.color)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(row.daysText)
                .font(AppFont.numeral(size: 15, relativeTo: .footnote))
                .foregroundStyle(row.color.textOnSurfaceContainer.color)
                .lineLimit(1)
        }
        .frame(minHeight: 22)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
    }
}

#Preview(as: .systemMedium) {
    UpcomingWidget()
} timeline: {
    UpcomingEntry.sample
    UpcomingEntry(date: .now, content: .rows([]))
    UpcomingEntry(date: .now, content: .unavailable)
}
