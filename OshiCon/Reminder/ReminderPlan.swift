//
//  ReminderPlan.swift
//  OshiCon
//

import Foundation

/// 予定の通知のタイミング。並びは設定の画面に出す順。
nonisolated enum ReminderTiming: String, CaseIterable, Codable, Sendable {
    /// 30 日前の、設定で選んだ時刻。
    case thirtyDaysBefore
    /// 7 日前の、設定で選んだ時刻。
    case sevenDaysBefore
    /// 前日の、設定で選んだ時刻。
    case dayBefore
    /// 当日の、設定で選んだ時刻。
    case onTheDay
    /// 開演（開始）の 1 時間前。開演の時刻がある予定だけ。
    case hourBeforeStart

    /// 開催日の何日前に出すか。開演 1 時間前は日付で決まらないので nil。
    var daysBefore: Int? {
        switch self {
        case .thirtyDaysBefore:
            30
        case .sevenDaysBefore:
            7
        case .dayBefore:
            1
        case .onTheDay:
            0
        case .hourBeforeStart:
            nil
        }
    }
}

/// 通知の設定。アプリ全体で 1 つ（予定ごとには持たない）。
nonisolated struct ReminderSettings: Hashable, Sendable {
    /// 予定を通知する。OFF なら何も予約しない。
    var isEnabled: Bool
    /// 出すタイミング。
    var timings: Set<ReminderTiming>
    /// 日付で決まる通知（N 日前・前日・当日）を出す時刻。
    var timeOfDay: TimeOfDay

    static let defaultTimeOfDay = TimeOfDay(hour: 9, minute: 0)
    /// 既定は、通知を ON にし、5 つのタイミングをすべて出し、9:00 に出す。
    static let `default` = Self(isEnabled: true, timings: Set(ReminderTiming.allCases), timeOfDay: defaultTimeOfDay)
}

/// 予約する通知 1 件。
nonisolated struct PlannedReminder: Hashable, Sendable {
    let eventID: OshiEvent.ID
    let timing: ReminderTiming
    /// 通知が知らせる開催日（毎年くり返す予定はその回）。
    let occurrenceDay: CalendarDay
    /// 出す日。予約は日付と時刻で行い、端末のタイムゾーンを変えても、その土地の同じ日付・時刻に出す（予定の日付・時刻を書いたまま数えるのと同じ）。
    let fireDay: CalendarDay
    /// 出す時刻。
    let fireTime: TimeOfDay
    /// 出す時点（計画を作った暦のタイムゾーン）。過ぎたかどうかと並びに使う。
    let fireDate: Date

    /// 予約の識別子。同じ予定・回・タイミングなら同じ値になり、予約し直しても重ならない。
    var identifier: String {
        "reminder.\(eventID.uuidString).\(occurrenceDay.year)-\(occurrenceDay.month)-\(occurrenceDay.day).\(timing.rawValue)"
    }
}

/// どの予定に、いつ通知を予約するか。`now` の時点の計画を、`calendar` のタイムゾーンで求める。
///
/// - 日付で決まる通知（N 日前・前日・当日）は、設定で選んだ時刻に出す
/// - 開演 1 時間前は、開演の時刻がある予定だけ。1 時間は実際の経過時間で数える（夏時間をまたいでも 1 時間前）
/// - 開演の時刻がある予定では、日付で決まる通知は、開演 1 時間前（その通知を出さない設定なら開演）より前に出るものだけ出す。
///   開演に間に合わない「当日」や、開演 1 時間前と重なる・後になる「当日」を出さないため
/// - 今より後の通知だけ。終わった予定と、過ぎたタイミングは出さない
/// - 毎年くり返す予定は、次の回とその次の回まで計画する（当日を過ぎてアプリを開かなくても、翌年の分が予約に残るように）
/// - 近い順に `limit` 件まで（iOS が予約を保てるのは 64 件）
nonisolated struct ReminderPlan: Hashable, Sendable {
    /// iOS がアプリごとに予約を保てる通知の数。
    static let maximumCount = 64

    /// 予約する通知。近い順。
    let reminders: [PlannedReminder]

    init(events: [OshiEvent], settings: ReminderSettings, now: Date, calendar: Calendar, limit: Int = maximumCount) {
        guard settings.isEnabled else {
            reminders = []
            return
        }
        let today = CalendarDay(now, calendar: calendar)
        let planned = events.flatMap { event in
            Self.occurrences(of: event, from: today).flatMap { occurrence in
                Self.reminders(for: event, on: occurrence, settings: settings, calendar: calendar)
            }
        }
        reminders = Array(
            planned
                .filter { $0.fireDate > now }
                .sorted(by: Self.isOrderedBefore)
                .prefix(max(limit, 0))
        )
    }

    /// 計画する開催日。毎年くり返す予定は次の回とその次の回（2/29 は平年 2/28）。
    private static func occurrences(of event: OshiEvent, from today: CalendarDay) -> [CalendarDay] {
        let occurrence = event.occurrence(from: today)
        guard event.repeatsYearly else {
            return [occurrence]
        }
        // その次の回は、登録した日付から求める（2/28 に寄せた回から求めると、閏年の 2/29 に戻れない）
        return [occurrence, event.day.withYear(occurrence.year + 1)]
    }

    /// 1 回の開催日に出す通知。過ぎたかどうかは呼ぶ側で確かめる。
    private static func reminders(
        for event: OshiEvent,
        on occurrence: CalendarDay,
        settings: ReminderSettings,
        calendar: Calendar
    ) -> [PlannedReminder] {
        let gregorian = CalendarDay.gregorian(matching: calendar)
        let start = event.startTime.map { occurrence.date(at: $0, calendar: gregorian) }
        let hourBeforeStart = start.map { $0.addingTimeInterval(-3_600) }
        let includesHourBeforeStart = settings.timings.contains(.hourBeforeStart)
        // 日付で決まる通知は、この時点より前に出るものだけ（開演の時刻が無ければ制限しない）
        let deadline = includesHourBeforeStart ? hourBeforeStart : start

        return ReminderTiming.allCases.filter(settings.timings.contains).compactMap { timing in
            if let daysBefore = timing.daysBefore {
                let fireDay = occurrence.adding(days: -daysBefore)
                let fireDate = fireDay.date(at: settings.timeOfDay, calendar: gregorian)
                if let deadline, fireDate >= deadline {
                    return nil
                }
                return PlannedReminder(
                    eventID: event.id,
                    timing: timing,
                    occurrenceDay: occurrence,
                    fireDay: fireDay,
                    fireTime: settings.timeOfDay,
                    fireDate: fireDate
                )
            }
            guard let hourBeforeStart else {
                return nil
            }
            return PlannedReminder(
                eventID: event.id,
                timing: timing,
                occurrenceDay: occurrence,
                fireDay: CalendarDay(hourBeforeStart, calendar: gregorian),
                fireTime: TimeOfDay(
                    hour: gregorian.component(.hour, from: hourBeforeStart),
                    minute: gregorian.component(.minute, from: hourBeforeStart)
                ),
                fireDate: hourBeforeStart
            )
        }
    }

    /// 近い順。同じ時点なら予定の id、同じ予定ならタイミングの並びで決める（並びが毎回変わらないように）。
    private static func isOrderedBefore(_ lhs: PlannedReminder, _ rhs: PlannedReminder) -> Bool {
        if lhs.fireDate != rhs.fireDate {
            return lhs.fireDate < rhs.fireDate
        }
        if lhs.eventID != rhs.eventID {
            return lhs.eventID.uuidString < rhs.eventID.uuidString
        }
        return timingOrder(lhs.timing) < timingOrder(rhs.timing)
    }

    private static func timingOrder(_ timing: ReminderTiming) -> Int {
        ReminderTiming.allCases.firstIndex(of: timing) ?? ReminderTiming.allCases.count
    }
}
