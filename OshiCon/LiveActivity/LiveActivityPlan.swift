//
//  LiveActivityPlan.swift
//  OshiCon
//

import Foundation

/// 1 件の予定のライブアクティビティを出す時間帯（開演の 3 時間前から、開演の 1 時間後まで）。
nonisolated struct LiveActivityWindow: Hashable, Sendable {
    let eventID: OshiEvent.ID
    /// 数える開催日（毎年くり返す予定はその回）。
    let occurrenceDay: CalendarDay
    /// 開演（開始）の時刻。
    let start: Date

    /// 出し始める時刻。
    var begin: Date {
        start.addingTimeInterval(-LiveActivityPlan.leadTime)
    }

    /// 終える時刻。
    var end: Date {
        start.addingTimeInterval(LiveActivityPlan.lingerTime)
    }
}

/// どの予定のライブアクティビティを、いつ出すか。`now` の時点の計画を、`calendar` のタイムゾーンで求める。
///
/// - 開演（開始）の時刻がある予定だけ。時刻の無い予定（誕生日など）には出さない
/// - 開演の 3 時間前から、開演の 1 時間後まで出す（iOS の上限は 8 時間）
/// - `current`: 今が時間帯に入っているもの。すぐに出す
/// - `scheduled`: これから時間帯が始まるもの。予約できる OS（iOS 26 以降）では、始まる時刻に予約する。
///   遠い先まで予約し続けないよう、`schedulingHorizon` の先までの近い順に `maximumScheduledCount` 件まで
nonisolated struct LiveActivityPlan: Hashable, Sendable {
    /// 開演の何秒前から出すか。
    static let leadTime: TimeInterval = 3 * 3_600
    /// 開演の何秒後まで出すか。
    static let lingerTime: TimeInterval = 3_600
    /// 予約する先の長さ。7 日前・前日の通知を押してアプリを開けば、そのときに予約し直せる。
    static let schedulingHorizon: TimeInterval = 8 * 86_400
    /// 予約しておく数の上限。
    static let maximumScheduledCount = 3

    /// 今出すもの。始まりの早い順。
    let current: [LiveActivityWindow]
    /// 予約するもの。始まりの早い順。
    let scheduled: [LiveActivityWindow]

    init(events: [OshiEvent], now: Date, calendar: Calendar) {
        let today = CalendarDay(now, calendar: calendar)
        let gregorian = CalendarDay.gregorian(matching: calendar)
        let windows = events
            .flatMap { event -> [LiveActivityWindow] in
                guard let startTime = event.startTime else {
                    return []
                }
                return Self.occurrences(of: event, from: today).map { occurrence in
                    LiveActivityWindow(
                        eventID: event.id,
                        occurrenceDay: occurrence,
                        start: occurrence.date(at: startTime, calendar: gregorian)
                    )
                }
            }
            .sorted(by: Self.isOrderedBefore)
        current = windows.filter { $0.begin <= now && now < $0.end }
        scheduled = Array(
            windows
                .filter { $0.begin > now && $0.begin <= now.addingTimeInterval(Self.schedulingHorizon) }
                .prefix(Self.maximumScheduledCount)
        )
    }

    /// 見る開催日。毎年くり返す予定は、前の回も見る（夜遅くの開演の時間帯は日付をまたぎ、
    /// 日付が変わると数える回が翌年に移るため）。
    private static func occurrences(of event: OshiEvent, from today: CalendarDay) -> [CalendarDay] {
        let occurrence = event.occurrence(from: today)
        guard let previous = event.previousOccurrence(before: occurrence) else {
            return [occurrence]
        }
        return [previous, occurrence]
    }

    /// 始まりの早い順。同じなら予定の id で決める（並びが毎回変わらないように）。
    private static func isOrderedBefore(_ lhs: LiveActivityWindow, _ rhs: LiveActivityWindow) -> Bool {
        if lhs.start != rhs.start {
            return lhs.start < rhs.start
        }
        return lhs.eventID.uuidString < rhs.eventID.uuidString
    }
}

extension EventActivityAttributes {
    /// 時間帯と予定から、ライブアクティビティの中身を作る。文言は `locale` の言語。
    nonisolated init(window: LiveActivityWindow, event: OshiEvent, oshi: Oshi?, locale: Locale = .app) {
        let startTime = event.startTime ?? TimeOfDay(hour: 0, minute: 0)
        self.init(
            eventID: event.id,
            heading: oshi?.name ?? event.kind.label(locale: locale),
            title: event.title,
            colorRawValue: (oshi?.color ?? .black).rawValue,
            startDate: window.start,
            countdownBegin: window.begin,
            untilText: EventText.untilLabel(kind: event.kind, hasStartTime: true, locale: locale),
            startText: EventText.startTime(startTime, kind: event.kind, locale: locale),
            startedText: String(localized: LocalizedStringResource("今日は当日！", locale: locale))
        )
    }
}
