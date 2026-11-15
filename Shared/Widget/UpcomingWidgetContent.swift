//
//  UpcomingWidgetContent.swift
//  OshiCon
//

import Foundation

/// 推しカウントウィジェット（これからの予定の一覧）に出す中身。ウィジェットから切り離してテストする。
nonisolated enum UpcomingWidgetContent: Equatable, Sendable {
    /// 当日とこれからの予定（近い順、先頭から `maxRows` 件まで）。空なら「これからの予定はありません」。
    case rows([Row])
    /// ストアを読めなかった。しばらくしてから読み直す。
    case unavailable

    /// 4×2 に収まる行の数。
    static let maxRows = 4

    /// 一覧の 1 行。
    struct Row: Identifiable, Equatable, Sendable {
        let id: OshiEvent.ID
        let title: String
        /// 推し色。推しなしの予定は、どの推し色とも紛れない無彩色。
        let color: OshiColor
        let status: CountdownStatus
        let daysUntil: Int
        /// 文言の言語。
        let locale: Locale

        /// 残り日数（`3日`。当日は `今日！`）。
        var daysText: String {
            EventText.compactDays(daysUntil: daysUntil, status: status, locale: locale)
        }

        /// 行の読み上げ（`5th LIVE、あと 3 日`）。
        var accessibilityLabel: String {
            EventText.joinedForSpeech([title, EventText.countdown(daysUntil: daysUntil, status: status, locale: locale)], locale: locale)
        }
    }

    init(events: [OshiEvent], oshis: [Oshi], today: CalendarDay, maxRows: Int, locale: Locale = .app) {
        let colors = Dictionary(oshis.map { ($0.id, $0.color) }) { first, _ in first }
        let rows = EventSchedule(events: events, today: today).upcoming.prefix(max(maxRows, 0)).map { scheduled in
            Row(
                id: scheduled.event.id,
                title: scheduled.event.title,
                color: scheduled.event.oshiID.flatMap { colors[$0] } ?? .black,
                status: scheduled.status,
                daysUntil: scheduled.daysUntil,
                locale: locale
            )
        }
        self = .rows(Array(rows))
    }
}
