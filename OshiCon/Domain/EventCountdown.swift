//
//  EventCountdown.swift
//  OshiCon
//

import Foundation

/// 詳細画面の秒単位のカウントダウン。`now` の時点の値を、`calendar` のタイムゾーンで求める。
nonisolated struct EventCountdown: Hashable, Sendable {
    /// 数える対象の開催日（毎年くり返す予定は次の回）。
    let occurrenceDay: CalendarDay
    /// 当日の開始の時刻（無ければ 0:00）の前は `.upcoming`、過ぎたら `.today`、終わった予定は `.ended`。
    let status: CountdownStatus
    /// 開始の時刻（無ければ開催日の 0:00）までの残り（秒）。始まった後と終わった予定は 0。
    let remaining: TimeInterval
    /// 開催日までの暦の日数。当日は 0、終わった予定は負。
    let daysUntil: Int
    /// 登録した時刻（毎年くり返す予定は、前の回の開始のほうが後ならそちら）から開始までの経過の割合（0〜1）。
    /// 起点が開始より後で求められないときは nil。
    let progress: Double?
    /// `progress` の起点の日付。
    let progressStartDay: CalendarDay

    init(event: OshiEvent, now: Date, calendar: Calendar) {
        let today = CalendarDay(now, calendar: calendar)
        let occurrence = event.occurrence(from: today)
        let target = occurrence.date(at: event.startTime, calendar: calendar)
        let daysUntil = today.days(until: occurrence)
        let status: CountdownStatus = if daysUntil < 0 {
            .ended
        } else if now >= target {
            .today
        } else {
            .upcoming
        }

        let previousStart = event.previousOccurrence(before: occurrence)
            .map { $0.date(at: event.startTime, calendar: calendar) }
        let progressStart = if let previousStart, previousStart > event.createdAt {
            previousStart
        } else {
            event.createdAt
        }

        self.occurrenceDay = occurrence
        self.status = status
        self.daysUntil = daysUntil
        self.progressStartDay = CalendarDay(progressStart, calendar: calendar)
        if status == .upcoming {
            remaining = target.timeIntervalSince(now)
            let total = target.timeIntervalSince(progressStart)
            progress = total > 0 ? min(max(now.timeIntervalSince(progressStart) / total, 0), 1) : nil
        } else {
            remaining = 0
            progress = 1
        }
    }

    /// 残りを日（24 時間単位）と時:分:秒に分けたもの。
    var remainingParts: RemainingParts {
        RemainingParts(remaining)
    }
}

/// 残りの時間を日（24 時間単位）と時:分:秒に分けたもの。1 秒未満は切り捨てる。
nonisolated struct RemainingParts: Hashable, Sendable {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int

    init(_ interval: TimeInterval) {
        let totalSeconds = max(Int(interval.rounded(.down)), 0)
        days = totalSeconds / 86_400
        hours = totalSeconds % 86_400 / 3_600
        minutes = totalSeconds % 3_600 / 60
        seconds = totalSeconds % 60
    }
}
