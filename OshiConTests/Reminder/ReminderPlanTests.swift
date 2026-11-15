//
//  ReminderPlanTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct ReminderPlanTests {
    private let calendar = DomainFixtures.tokyo

    private func plan(
        _ events: [OshiEvent],
        settings: ReminderSettings = .default,
        now: Date,
        calendar: Calendar = DomainFixtures.tokyo,
        limit: Int = ReminderPlan.maximumCount
    ) -> [PlannedReminder] {
        ReminderPlan(events: events, settings: settings, now: now, calendar: calendar, limit: limit).reminders
    }

    private func settings(
        _ timings: Set<ReminderTiming> = Set(ReminderTiming.allCases),
        at time: TimeOfDay = TimeOfDay(hour: 9, minute: 0)
    ) -> ReminderSettings {
        ReminderSettings(isEnabled: true, timings: timings, timeOfDay: time)
    }

    @Test("開演の時刻がある予定は 5 つのタイミングを近い順に。日付で決まる通知は設定の時刻に出す")
    func allTimingsWithStartTime() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18), startTime: TimeOfDay(hour: 17, minute: 0))
        let reminders = plan([event], now: DomainFixtures.date(2026, 9, 1, 12, 0))
        #expect(reminders.map(\.timing) == [.thirtyDaysBefore, .sevenDaysBefore, .dayBefore, .onTheDay, .hourBeforeStart])
        #expect(reminders.map(\.fireDay) == [
            DomainFixtures.day(2026, 9, 18),
            DomainFixtures.day(2026, 10, 11),
            DomainFixtures.day(2026, 10, 17),
            DomainFixtures.day(2026, 10, 18),
            DomainFixtures.day(2026, 10, 18)
        ])
        #expect(reminders.map(\.fireTime) == [
            TimeOfDay(hour: 9, minute: 0),
            TimeOfDay(hour: 9, minute: 0),
            TimeOfDay(hour: 9, minute: 0),
            TimeOfDay(hour: 9, minute: 0),
            TimeOfDay(hour: 16, minute: 0)
        ])
        #expect(reminders.last?.fireDate == DomainFixtures.date(2026, 10, 18, 16, 0))
        #expect(reminders.allSatisfy { $0.eventID == event.id && $0.occurrenceDay == DomainFixtures.day(2026, 10, 18) })
    }

    @Test("開演の時刻が無い予定は、開演 1 時間前を出さない")
    func noHourBeforeWithoutStartTime() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18))
        let reminders = plan([event], now: DomainFixtures.date(2026, 9, 1))
        #expect(reminders.map(\.timing) == [.thirtyDaysBefore, .sevenDaysBefore, .dayBefore, .onTheDay])
        #expect(reminders.last?.fireDate == DomainFixtures.date(2026, 10, 18, 9, 0))
    }

    @Test("設定で選んだタイミングと時刻だけ")
    func selectedTimingsAndTime() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18), startTime: TimeOfDay(hour: 17, minute: 0))
        let reminders = plan(
            [event],
            settings: settings([.dayBefore, .onTheDay], at: TimeOfDay(hour: 20, minute: 30)),
            now: DomainFixtures.date(2026, 9, 1)
        )
        // 当日の 20:30 は開演より後なので出さない
        #expect(reminders.map(\.timing) == [.dayBefore])
        #expect(reminders.first?.fireDate == DomainFixtures.date(2026, 10, 17, 20, 30))
    }

    @Test("通知が OFF なら何も予約しない")
    func disabled() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18))
        var settings = ReminderSettings.default
        settings.isEnabled = false
        #expect(plan([event], settings: settings, now: DomainFixtures.date(2026, 9, 1)).isEmpty)
    }

    @Test("今より前の時刻は出さない。ちょうど今の時刻も出さない")
    func skipsPastTimings() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18))
        // 予定の 10 日前に登録した: 30 日前は過ぎている
        #expect(plan([event], now: DomainFixtures.date(2026, 10, 8, 12, 0)).map(\.timing) == [.sevenDaysBefore, .dayBefore, .onTheDay])
        #expect(plan([event], now: DomainFixtures.date(2026, 10, 17, 9, 0)).map(\.timing) == [.onTheDay])
        #expect(plan([event], now: DomainFixtures.date(2026, 10, 17, 8, 59, 59)).map(\.timing) == [.dayBefore, .onTheDay])
    }

    @Test("終わった予定は出さない")
    func skipsEndedEvents() {
        let ended = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 15))
        #expect(plan([ended], now: DomainFixtures.date(2026, 10, 18)).isEmpty)
    }

    @Test("当日の通知は、開演 1 時間前より前に出るときだけ")
    func onTheDayBeforeHourBeforeStart() {
        let now = DomainFixtures.date(2026, 10, 1)
        func timings(startingAt hour: Int, _ minute: Int) -> [ReminderTiming] {
            let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18), startTime: TimeOfDay(hour: hour, minute: minute))
            return plan([event], settings: settings([.onTheDay, .hourBeforeStart]), now: now).map(\.timing)
        }
        // 開演 11:00: 当日 9:00 は 1 時間前（10:00）より前
        #expect(timings(startingAt: 11, 0) == [.onTheDay, .hourBeforeStart])
        // 開演 10:00: 当日 9:00 と 1 時間前が重なるので、1 時間前だけ
        #expect(timings(startingAt: 10, 0) == [.hourBeforeStart])
        // 開演 9:30: 当日 9:00 が 1 時間前（8:30）より後になるので、1 時間前だけ
        #expect(timings(startingAt: 9, 30) == [.hourBeforeStart])
        // 開演 8:00: 当日 9:00 は開演に間に合わない
        #expect(timings(startingAt: 8, 0) == [.hourBeforeStart])
    }

    @Test("開演 1 時間前を出さない設定なら、当日の通知は開演より前に出るときだけ")
    func onTheDayBeforeStartWithoutHourBefore() {
        let now = DomainFixtures.date(2026, 10, 1)
        func timings(startingAt hour: Int, _ minute: Int) -> [ReminderTiming] {
            let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18), startTime: TimeOfDay(hour: hour, minute: minute))
            return plan([event], settings: settings([.onTheDay]), now: now).map(\.timing)
        }
        #expect(timings(startingAt: 9, 30) == [.onTheDay])
        #expect(timings(startingAt: 9, 0).isEmpty)
        #expect(timings(startingAt: 8, 0).isEmpty)
    }

    @Test("開演が 0 時台なら、1 時間前は前日。前日の通知もその前に出るときだけ")
    func startJustAfterMidnight() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18), startTime: TimeOfDay(hour: 0, minute: 30))
        let now = DomainFixtures.date(2026, 10, 1)
        let reminders = plan([event], settings: settings([.dayBefore, .onTheDay, .hourBeforeStart]), now: now)
        #expect(reminders.map(\.timing) == [.dayBefore, .hourBeforeStart])
        #expect(reminders.last?.fireDay == DomainFixtures.day(2026, 10, 17))
        #expect(reminders.last?.fireTime == TimeOfDay(hour: 23, minute: 30))

        let late = plan([event], settings: settings([.dayBefore, .hourBeforeStart], at: TimeOfDay(hour: 23, minute: 45)), now: now)
        #expect(late.map(\.timing) == [.hourBeforeStart])
    }

    @Test("開演 1 時間前は実際の経過時間で数える（夏時間が始まる日）")
    func hourBeforeAcrossDaylightSavingTime() {
        let newYork = DomainFixtures.calendar(timeZone: "America/New_York")
        // 2026-03-08 2:00 に夏時間が始まり、時計が 3:00 に進む。3:30 の 1 時間前は 1:30
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 3, 8), startTime: TimeOfDay(hour: 3, minute: 30))
        let reminders = plan(
            [event],
            settings: settings([.hourBeforeStart]),
            now: DomainFixtures.date(2026, 3, 1, calendar: newYork),
            calendar: newYork
        )
        #expect(reminders.first?.fireDay == DomainFixtures.day(2026, 3, 8))
        #expect(reminders.first?.fireTime == TimeOfDay(hour: 1, minute: 30))
        #expect(reminders.first?.fireDate == DomainFixtures.date(2026, 3, 8, 3, 30, calendar: newYork).addingTimeInterval(-3_600))
    }

    @Test("日付と時刻は書いたまま。タイムゾーンが違っても同じ日付・時刻に出す")
    func sameWallClockInAnyTimeZone() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18), startTime: TimeOfDay(hour: 17, minute: 0))
        let newYork = DomainFixtures.calendar(timeZone: "America/New_York")
        let inTokyo = plan([event], now: DomainFixtures.date(2026, 9, 1))
        let inNewYork = plan([event], now: DomainFixtures.date(2026, 9, 1, calendar: newYork), calendar: newYork)
        #expect(inTokyo.map(\.fireDay) == inNewYork.map(\.fireDay))
        #expect(inTokyo.map(\.fireTime) == inNewYork.map(\.fireTime))
        #expect(inNewYork.first?.fireDate == DomainFixtures.date(2026, 9, 18, 9, 0, calendar: newYork))
    }

    @Test("毎年くり返す予定は、次の回とその次の回まで")
    func repeatingPlansNextTwoOccurrences() {
        let birthday = DomainFixtures.event(day: DomainFixtures.day(2000, 10, 18), repeatsYearly: true)
        let reminders = plan([birthday], now: DomainFixtures.date(2026, 10, 1))
        // 今年の 30 日前（9/18）は過ぎている
        #expect(reminders.map(\.occurrenceDay) == [
            DomainFixtures.day(2026, 10, 18),
            DomainFixtures.day(2026, 10, 18),
            DomainFixtures.day(2026, 10, 18),
            DomainFixtures.day(2027, 10, 18),
            DomainFixtures.day(2027, 10, 18),
            DomainFixtures.day(2027, 10, 18),
            DomainFixtures.day(2027, 10, 18)
        ])
        #expect(reminders.map(\.timing) == [
            .sevenDaysBefore, .dayBefore, .onTheDay,
            .thirtyDaysBefore, .sevenDaysBefore, .dayBefore, .onTheDay
        ])
    }

    @Test("毎年くり返す予定の当日を過ぎたら、翌年の回を出す")
    func repeatingAfterTheDay() {
        let birthday = DomainFixtures.event(day: DomainFixtures.day(2000, 10, 18), repeatsYearly: true)
        let reminders = plan([birthday], now: DomainFixtures.date(2026, 10, 18, 10, 0))
        // 今年の回は当日の 9:00 を過ぎて出すものが残っていないので、翌年の回だけ
        #expect(reminders.map(\.timing) == [.thirtyDaysBefore, .sevenDaysBefore, .dayBefore, .onTheDay])
        #expect(reminders.allSatisfy { $0.occurrenceDay == DomainFixtures.day(2027, 10, 18) })
    }

    @Test("2/29 の予定は、平年は 2/28、閏年は 2/29 に数える")
    func leapDay() {
        let birthday = DomainFixtures.event(day: DomainFixtures.day(2000, 2, 29), repeatsYearly: true)
        let reminders = plan([birthday], settings: settings([.onTheDay]), now: DomainFixtures.date(2026, 3, 1))
        #expect(reminders.map(\.fireDay) == [DomainFixtures.day(2027, 2, 28), DomainFixtures.day(2028, 2, 29)])
    }

    @Test("数えきれないときは、近い順に上限まで")
    func limitKeepsNearest() {
        let far = DomainFixtures.event(title: "遠い", day: DomainFixtures.day(2026, 12, 1))
        let near = DomainFixtures.event(title: "近い", day: DomainFixtures.day(2026, 10, 18))
        let reminders = plan([far, near], settings: settings([.dayBefore, .onTheDay]), now: DomainFixtures.date(2026, 10, 1), limit: 3)
        #expect(reminders.map(\.eventID) == [near.id, near.id, far.id])
        #expect(reminders.map(\.timing) == [.dayBefore, .onTheDay, .dayBefore])
    }

    @Test("既定の上限は iOS が予約を保てる 64 件")
    func defaultLimit() {
        let events = (1...20).map { DomainFixtures.event(title: "予定 \($0)", day: DomainFixtures.day(2026, 12, $0)) }
        let reminders = plan(events, now: DomainFixtures.date(2026, 10, 1))
        #expect(reminders.count == 64)
        #expect(reminders.map(\.fireDate) == reminders.map(\.fireDate).sorted())
    }

    @Test("識別子は予定・回・タイミングで決まり、計画し直しても変わらない")
    func stableIdentifiers() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18), startTime: TimeOfDay(hour: 17, minute: 0))
        let earlier = plan([event], now: DomainFixtures.date(2026, 9, 1))
        let later = plan([event], now: DomainFixtures.date(2026, 10, 12))
        #expect(Set(later.map(\.identifier)).isSubset(of: Set(earlier.map(\.identifier))))
        #expect(Set(earlier.map(\.identifier)).count == earlier.count)
        #expect(earlier.first?.identifier == "reminder.\(event.id.uuidString).2026-10-18.thirtyDaysBefore")
    }
}
