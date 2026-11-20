//
//  ReminderContent.swift
//  OshiCon
//

import Foundation

/// 予定の通知の文面。文言は `locale` の言語、日付・時刻は `locale` の書き方で出す。
///
/// - タイトル: 予定のタイトル
/// - サブタイトル: 推しの名前（推しなしの予定は種類）。ウィジェットのカウントダウンと同じ
/// - 本文: タイミングの文言（`あと 7 日`・`いよいよ明日！`・`今日！`・`あと 1 時間`）に、前の日に出すものは開催日、開始の時刻があればそれを続ける
nonisolated struct ReminderContent: Hashable, Sendable {
    let title: String
    let subtitle: String
    let body: String

    init(reminder: PlannedReminder, event: OshiEvent, oshiName: String?, locale: Locale = .app) {
        title = event.title
        subtitle = oshiName ?? event.kind.label(locale: locale)

        var parts = [Self.lead(for: reminder.timing, locale: locale)]
        // 当日と開演 1 時間前は今日のことなので、日付は出さない
        if let daysBefore = reminder.timing.daysBefore, daysBefore > 0 {
            parts.append(EventText.monthDayWeekday(reminder.occurrenceDay, locale: locale))
        }
        if let startTime = event.startTime {
            parts.append(EventText.startTime(startTime, kind: event.kind, locale: locale))
        }
        // ホームの一覧の行（`日付 · 推しの名前`）と同じ区切り
        body = parts.joined(separator: " · ")
    }

    private static func lead(for timing: ReminderTiming, locale: Locale) -> String {
        switch timing {
        case .thirtyDaysBefore, .sevenDaysBefore:
            EventText.countdown(daysUntil: timing.daysBefore ?? 0, status: .upcoming, locale: locale)
        case .dayBefore:
            String(localized: LocalizedStringResource("いよいよ明日！", locale: locale, comment: "前日の通知の本文"))
        case .onTheDay:
            EventText.today(locale: locale)
        case .hourBeforeStart:
            String(localized: LocalizedStringResource("あと 1 時間", locale: locale, comment: "開始の 1 時間前の通知の本文"))
        }
    }
}
