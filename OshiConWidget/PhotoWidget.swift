//
//  PhotoWidget.swift
//  OshiConWidget
//

import CoreGraphics
import SwiftUI
import WidgetKit

/// 推しの写真ウィジェット（Plus）。選んだ予定の推しの写真を背景に「あと N 日」を出す。小は写真の全面に日数と予定名、
/// 中は左に写真、右に推し名・予定名・日数・日付。Plus でなければ見本を薄く出して「Plus で使えます」を重ねる。
/// 押すと Plus なら予定の詳細、Plus でなければ課金画面（入口を出さない配り方では予定の詳細）を開く。
/// 0:00 と Plus の期限のエントリで、日付が変わったら数え直し、期限を過ぎたら Plus を確かめ直す。
struct PhotoWidget: Widget {
    static let kind = "jp.shilokuma.OshiCon.Photo"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: SelectEventIntent.self, provider: PhotoProvider()) { entry in
            PhotoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("推しの写真")
        .description("推しの写真を背景に、選んだ予定まであと何日かを表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
        // 写真は 1 色の描き方でも見えるよう地ではなく中身に置くので、余白は View が付ける（`PhotoWidgetView`）
        .contentMarginsDisabled()
    }
}

/// 小と中で、中身の描き方を分ける。
private struct PhotoWidgetEntryView: View {
    let entry: PhotoEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        PhotoWidgetView(
            content: entry.content,
            family: family == .systemMedium ? .systemMedium : .systemSmall,
            photo: entry.photo
        )
        .environment(\.appTheme, .shipping(themeColor: entry.themeColor))
    }
}

nonisolated struct PhotoEntry: TimelineEntry {
    let date: Date
    let content: PhotoWidgetContent
    /// ウィジェットの大きさに縮めて読んだ推しの写真。無い・読めないときは nil（推し色の模様）。
    let photo: CGImage?
    /// テーマを染める色（1 位の推しの推し色）。見本・読めないときは nil（ピンクのまま）。
    var themeColor: OshiColor?

    /// ウィジェットの一覧に出す見本。
    static func sample(isPlusUnlocked: Bool) -> Self {
        Self(date: .now, content: .sample(isPlusUnlocked: isPlusUnlocked), photo: nil)
    }
}

nonisolated struct PhotoProvider: AppIntentTimelineProvider {
    /// 先に作っておく 0:00 のエントリの数。使い切ったら作り直す。
    private static let midnightCount = 7
    /// ストアを読めなかったとき、読み直すまでの間隔。
    private static let retryInterval: TimeInterval = 15 * 60
    /// 写真を読む画面の倍率。Widget Extension では画面の倍率が分からないので、いちばん大きい倍率で読む
    /// （上限は `WidgetPhotoLoader.maxPixelLength`）。
    private static let photoScale: CGFloat = 3

    func placeholder(in context: Context) -> PhotoEntry {
        .sample(isPlusUnlocked: true)
    }

    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> PhotoEntry {
        let now = Date.now
        let plus = await PlusWidgetStatus().resolve(now: now)
        // ウィジェットの一覧では見本を出す（Plus でなければ、薄くして「Plus で使えます」を重ねたもの）
        if context.isPreview, configuration.event == nil {
            return .sample(isPlusUnlocked: plus.isUnlocked)
        }
        guard let data = await WidgetStore.load() else {
            return PhotoEntry(date: now, content: .unavailable, photo: nil)
        }
        let content = Self.content(
            at: now,
            isPlusUnlocked: plus.isUnlocked,
            configuration: configuration,
            data: data,
            calendar: .autoupdatingCurrent
        )
        return PhotoEntry(date: now, content: content, photo: Self.photo(for: content, in: context), themeColor: data.themeColor)
    }

    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<PhotoEntry> {
        let now = Date.now
        guard let data = await WidgetStore.load() else {
            // 読めないことを「予定が見つかりません」と出し続けないよう、しばらくしてから読み直す
            return Timeline(
                entries: [PhotoEntry(date: now, content: .unavailable, photo: nil)],
                policy: .after(now.addingTimeInterval(Self.retryInterval))
            )
        }
        let calendar = Calendar.autoupdatingCurrent
        let plus = await PlusWidgetStatus().resolve(now: now)
        let plan = PhotoWidgetTimeline.plan(now: now, plus: plus, midnightCount: Self.midnightCount, calendar: calendar)
        let contents = plan.moments.map { moment in
            Self.content(
                at: moment.date,
                isPlusUnlocked: moment.isPlusUnlocked,
                configuration: configuration,
                data: data,
                calendar: calendar
            )
        }
        // 写真はどのエントリでも同じ推しのものなので、1 回だけ読む
        let photo = contents.first.flatMap { Self.photo(for: $0, in: context) }
        let entries = zip(plan.moments, contents).map { moment, content in
            PhotoEntry(date: moment.date, content: content, photo: photo, themeColor: data.themeColor)
        }
        // 期限がエントリの範囲の中にあれば、期限の時刻に作り直して Plus を確かめ直す
        let policy: TimelineReloadPolicy = plan.reloadDate.map { .after($0) } ?? .atEnd
        return Timeline(entries: entries, policy: policy)
    }

    private static func content(
        at date: Date,
        isPlusUnlocked: Bool,
        configuration: SelectEventIntent,
        data: WidgetData,
        calendar: Calendar
    ) -> PhotoWidgetContent {
        PhotoWidgetContent(
            eventID: configuration.event?.id,
            events: data.events,
            oshis: data.oshis,
            isPlusUnlocked: isPlusUnlocked,
            today: CalendarDay(date, calendar: calendar)
        )
    }

    /// 推しの写真を、ウィジェットの写真の枠（小は全面、中は高さいっぱいの正方形）の大きさに縮めて読む。
    private static func photo(for content: PhotoWidgetContent, in context: Context) -> CGImage? {
        guard case let .event(event) = content, let fileName = event.photoFileName else {
            return nil
        }
        let size = context.displaySize
        let pointLength = context.family == .systemMedium ? size.height : max(size.width, size.height)
        let pixelLength = WidgetPhotoLoader.pixelLength(pointLength: pointLength, scale: photoScale)
        return WidgetPhotoLoader().loadImage(fileName: fileName, pixelLength: pixelLength)
    }
}

#Preview(as: .systemSmall) {
    PhotoWidget()
} timeline: {
    PhotoEntry.sample(isPlusUnlocked: true)
    PhotoEntry.sample(isPlusUnlocked: false)
    PhotoEntry(date: .now, content: .notSelected, photo: nil)
    PhotoEntry(date: .now, content: .missing, photo: nil)
    PhotoEntry(date: .now, content: .unavailable, photo: nil)
}

#Preview("中", as: .systemMedium) {
    PhotoWidget()
} timeline: {
    PhotoEntry.sample(isPlusUnlocked: true)
    PhotoEntry.sample(isPlusUnlocked: false)
    PhotoEntry(date: .now, content: .notSelected, photo: nil)
}
