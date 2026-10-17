//
//  EventSchedule.swift
//  OshiCon
//

import Foundation

/// 開催日から見た今日の位置。
nonisolated enum CountdownStatus: Hashable, Sendable {
    /// 開催日はまだ先。詳細のカウントダウンでは、当日でも開始の時刻の前はこれ。
    case upcoming
    /// 開催日の当日。詳細のカウントダウンでは、当日の開始の時刻を過ぎたもの。
    case today
    /// 終わった（くり返さない予定で、開催日を過ぎた）。
    case ended
}

/// 今日から見た予定。
nonisolated struct ScheduledEvent: Hashable, Sendable {
    let event: OshiEvent
    /// 数える対象の開催日（毎年くり返す予定は次の回）。
    let occurrenceDay: CalendarDay
    /// 開催日までの暦の日数。当日は 0、終わった予定は負。
    let daysUntil: Int
    let status: CountdownStatus

    init(event: OshiEvent, today: CalendarDay) {
        self.event = event
        occurrenceDay = event.occurrence(from: today)
        daysUntil = today.days(until: occurrenceDay)
        status = if daysUntil > 0 {
            .upcoming
        } else if daysUntil == 0 {
            .today
        } else {
            .ended
        }
    }
}

/// ホームに出す予定の並び。
nonisolated struct EventSchedule: Hashable, Sendable {
    /// 先頭に大きく出す予定。ピン留めした予定がまだ終わっていなければそれ、無ければいちばん近い予定。
    let featured: ScheduledEvent?
    /// 当日とこれからの予定。近い順。同じ日は時刻の無い予定（終日）、時刻の早い順、登録した順。
    let upcoming: [ScheduledEvent]
    /// 終わった予定。新しい順。
    let past: [ScheduledEvent]

    init(events: [OshiEvent], today: CalendarDay) {
        let scheduled = events.map { ScheduledEvent(event: $0, today: today) }
        upcoming = scheduled
            .filter { $0.status != .ended }
            .sorted(by: Self.isOrderedBeforeInUpcoming)
        past = scheduled
            .filter { $0.status == .ended }
            .sorted { Self.isOrderedBeforeInUpcoming($1, $0) }
        featured = upcoming.first { $0.event.isPinned } ?? upcoming.first
    }

    /// これからの予定の並び。終わった予定はこの逆に並べる。
    private static func isOrderedBeforeInUpcoming(_ lhs: ScheduledEvent, _ rhs: ScheduledEvent) -> Bool {
        if lhs.occurrenceDay != rhs.occurrenceDay {
            return lhs.occurrenceDay < rhs.occurrenceDay
        }
        // 時刻の無い予定（終日）は 0:00 の予定より前に置く
        let lhsMinutes = lhs.event.startTime?.minutesSinceMidnight ?? -1
        let rhsMinutes = rhs.event.startTime?.minutesSinceMidnight ?? -1
        if lhsMinutes != rhsMinutes {
            return lhsMinutes < rhsMinutes
        }
        if lhs.event.createdAt != rhs.event.createdAt {
            return lhs.event.createdAt < rhs.event.createdAt
        }
        // 並びが毎回変わらないよう、最後は id で決める
        return lhs.event.id.uuidString < rhs.event.id.uuidString
    }
}
