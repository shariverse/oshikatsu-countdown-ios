//
//  OshiListContent.swift
//  OshiCon
//

import Foundation

/// 推しの一覧に出す中身（画面から切り離してテストする）。推しを並びの順に、予定の件数と次の予定を付けて持つ。
nonisolated struct OshiListContent: Equatable, Sendable {
    /// 推しの一覧の 1 人分。
    struct Row: Identifiable, Equatable, Sendable {
        let oshi: Oshi
        /// 並びの順位（いちばん上が 1）。
        let rank: Int
        /// 結び付いた予定の件数。終わった予定も数える。
        let eventCount: Int
        /// 次の予定。当日とこれからの予定のうち、いちばん近いもの（同じ日の並びはホームと同じ）。無ければ nil。
        let nextEvent: ScheduledEvent?
        /// 文言と日付の書き方の言語。
        let locale: Locale

        var id: Oshi.ID {
            oshi.id
        }

        /// 1 位の推しのカードのリボンの札（`最推し！`）。順位の数字は出さず、いちばんの推しだと伝える。
        var topRibbonText: String {
            String(localized: LocalizedStringResource("最推し！", locale: locale))
        }

        /// 予定の件数（`予定 3 件`）。
        var eventCountText: String {
            String(localized: LocalizedStringResource("予定 \(eventCount) 件", locale: locale))
        }

        /// 次の予定の日付（`10月25日(日)`）。行では、次の予定のタイトルの後ろに `·` でつないで出す。次の予定が無ければ nil。
        var nextEventDateText: String? {
            nextEvent.map { EventText.monthDayWeekday($0.occurrenceDay, locale: locale) }
        }

        /// 次の予定までの残り日数（`あと 7 日`・`今日！`）。次の予定が無ければ nil。
        var countdownText: String? {
            nextEvent.map { EventText.countdown(daysUntil: $0.daysUntil, status: $0.status, locale: locale) }
        }

        /// 行の読み上げ（`ミナト、誕生日、10月25日 日曜日、あと 7 日`。次の予定が無ければ `ミナト、予定 0 件`）。
        var accessibilityLabel: String {
            EventText.joinedForSpeech([oshi.name] + nextEventSpeech(orEventCount: true), locale: locale)
        }

        /// 1 位の推しのカードの読み上げ（`最推し！、テーマカラー、LUMINA、5th LIVE、10月25日 日曜日、あと 7 日、予定 2 件`）。
        var topAccessibilityLabel: String {
            let themeColor = String(localized: LocalizedStringResource("テーマカラー", locale: locale))
            return EventText.joinedForSpeech(
                [topRibbonText, themeColor, oshi.name] + nextEventSpeech(orEventCount: false) + [eventCountText],
                locale: locale
            )
        }

        /// 次の予定のタイトル・日付・残り日数の読み上げ。次の予定が無いときは、`orEventCount` なら予定の件数、そうでなければ空。
        private func nextEventSpeech(orEventCount: Bool) -> [String] {
            guard let nextEvent, let countdownText else {
                return orEventCount ? [eventCountText] : []
            }
            return [nextEvent.event.title, EventText.spokenMonthDayWeekday(nextEvent.occurrenceDay, locale: locale), countdownText]
        }
    }

    /// 推し。並びの順（いちばん上が 1 位）。
    let rows: [Row]

    /// 1 位の推し（大きいカードで出す）。推しがいなければ nil。
    var top: Row? {
        rows.first
    }

    /// 2 位からの推し。
    var others: [Row] {
        Array(rows.dropFirst())
    }

    /// `oshis` は並びの順（`OshiConStore.oshiOrder`）。予定は推しごとに分け、推しなしの予定・推しが見つからない予定は数えない。
    init(oshis: [Oshi], events: [OshiEvent], today: CalendarDay, locale: Locale = .app) {
        let eventsByOshi = Dictionary(grouping: events) { $0.oshiID }
        rows = oshis.enumerated().map { index, oshi in
            let events = eventsByOshi[oshi.id] ?? []
            return Row(
                oshi: oshi,
                rank: index + 1,
                eventCount: events.count,
                // これからの予定の並び（近い順。同じ日は終日・時刻の早い順・登録した順）の先頭。ピン留めは見ない
                nextEvent: EventSchedule(events: events, today: today).upcoming.first,
                locale: locale
            )
        }
    }

    /// 今の時刻 `now` を `calendar` のタイムゾーンで見た日付で数える。
    init(oshis: [Oshi], events: [OshiEvent], now: Date, calendar: Calendar, locale: Locale = .app) {
        self.init(oshis: oshis, events: events, today: CalendarDay(now, calendar: calendar), locale: locale)
    }
}
