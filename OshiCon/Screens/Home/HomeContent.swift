//
//  HomeContent.swift
//  OshiCon
//

import Foundation

/// ホームに出す中身（画面から切り離してテストする）。推しで絞り込み、先頭の予定・これからの予定・終わった予定に分ける。
nonisolated struct HomeContent: Equatable, Sendable {
    /// ホームの予定の 1 件。
    struct Item: Identifiable, Equatable, Sendable {
        let scheduled: ScheduledEvent
        /// 結び付いた推し。推しなしの予定・推しが見つからない予定は nil。
        let oshi: Oshi?

        var id: OshiEvent.ID {
            scheduled.event.id
        }

        var event: OshiEvent {
            scheduled.event
        }

        /// 塗り・残り日数の文字の色。推しなしの予定は、どの推し色とも紛れない無彩色（Android 版と同じ）。
        var color: OshiColor {
            oshi?.color ?? .black
        }

        /// 行の補足（`10月18日(日) · ミナト`、毎年くり返す予定は `· 毎年`）。
        var supportingText: String {
            let detail = event.repeatsYearly ? "毎年" : (oshi?.name ?? "推しなし")
            return "\(EventText.monthDayWeekday(scheduled.occurrenceDay)) · \(detail)"
        }

        var countdownText: String {
            EventText.countdown(daysUntil: scheduled.daysUntil, status: scheduled.status)
        }
    }

    /// 何も出す予定が無いときの案内。
    enum EmptyState: Equatable, Sendable {
        /// 予定が 1 件も無い。
        case noEvents
        /// 絞り込んだ推しの予定が無い。
        case noEventsForOshi
    }

    /// 絞り込みに出す推し（登録した順）。推しが 1 人もいなければ空で、絞り込みを出さない。
    let oshis: [Oshi]
    /// 絞り込み中の推し。すべてのときと、選んでいた推しが消えたときは nil。
    let selectedOshiID: Oshi.ID?
    let featured: Item?
    let upcoming: [Item]
    /// 終わった予定。設定で表示しないときは空。
    let past: [Item]
    let emptyState: EmptyState?

    init(events: [OshiEvent], oshis: [Oshi], selectedOshiID: Oshi.ID?, showsPastEvents: Bool, today: CalendarDay) {
        let oshiByID = Dictionary(oshis.map { ($0.id, $0) }) { first, _ in first }
        let validSelectedID = selectedOshiID.flatMap { oshiByID[$0] == nil ? nil : $0 }
        let filtered = validSelectedID.map { id in events.filter { $0.oshiID == id } } ?? events
        let schedule = EventSchedule(events: filtered, today: today)
        let item = { (scheduled: ScheduledEvent) in
            Item(scheduled: scheduled, oshi: scheduled.event.oshiID.flatMap { oshiByID[$0] })
        }

        self.oshis = oshis
        self.selectedOshiID = validSelectedID
        featured = schedule.featured.map(item)
        upcoming = schedule.upcoming.map(item)
        past = showsPastEvents ? schedule.past.map(item) : []
        emptyState = if events.isEmpty {
            .noEvents
        } else if filtered.isEmpty {
            .noEventsForOshi
        } else {
            nil
        }
    }
}
