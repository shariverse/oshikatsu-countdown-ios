//
//  LiveActivityPlanTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct LiveActivityPlanTests {
    private func plan(_ events: [OshiEvent], now: Date, calendar: Calendar = DomainFixtures.tokyo) -> LiveActivityPlan {
        LiveActivityPlan(events: events, now: now, calendar: calendar)
    }

    private func live(
        _ title: String = "ライブ",
        day: CalendarDay,
        at hour: Int,
        _ minute: Int = 0,
        repeatsYearly: Bool = false
    ) -> OshiEvent {
        DomainFixtures.event(title: title, day: day, startTime: TimeOfDay(hour: hour, minute: minute), repeatsYearly: repeatsYearly)
    }

    @Test("開演の 3 時間前から、開演の 1 時間後まで出す")
    func windowBounds() {
        let event = live(day: DomainFixtures.day(2026, 10, 18), at: 17)
        #expect(plan([event], now: DomainFixtures.date(2026, 10, 18, 13, 59, 59)).current.isEmpty)
        #expect(plan([event], now: DomainFixtures.date(2026, 10, 18, 14, 0)).current.map(\.eventID) == [event.id])
        #expect(plan([event], now: DomainFixtures.date(2026, 10, 18, 17, 30)).current.map(\.eventID) == [event.id])
        #expect(plan([event], now: DomainFixtures.date(2026, 10, 18, 18, 0)).current.isEmpty)

        let window = plan([event], now: DomainFixtures.date(2026, 10, 18, 15, 0)).current.first
        #expect(window?.start == DomainFixtures.date(2026, 10, 18, 17, 0))
        #expect(window?.begin == DomainFixtures.date(2026, 10, 18, 14, 0))
        #expect(window?.end == DomainFixtures.date(2026, 10, 18, 18, 0))
        #expect(window?.occurrenceDay == DomainFixtures.day(2026, 10, 18))
    }

    @Test("開演の時刻が無い予定には出さない")
    func skipsEventsWithoutStartTime() {
        let birthday = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18))
        let result = plan([birthday], now: DomainFixtures.date(2026, 10, 18, 12, 0))
        #expect(result.current.isEmpty)
        #expect(result.scheduled.isEmpty)
    }

    @Test("時間帯が始まる前の予定は、始まる時刻に予約する")
    func schedulesUpcomingWindows() {
        let event = live(day: DomainFixtures.day(2026, 10, 18), at: 17)
        let result = plan([event], now: DomainFixtures.date(2026, 10, 15, 12, 0))
        #expect(result.current.isEmpty)
        #expect(result.scheduled.map(\.eventID) == [event.id])
        #expect(result.scheduled.first?.begin == DomainFixtures.date(2026, 10, 18, 14, 0))
    }

    @Test("予約するのは 8 日先までの、近い順に 3 件まで")
    func schedulingLimits() {
        let now = DomainFixtures.date(2026, 10, 1, 12, 0)
        let events = (2...6).map { live("予定 \($0)", day: DomainFixtures.day(2026, 10, $0), at: 18) }
        let far = live("遠い", day: DomainFixtures.day(2026, 10, 20), at: 18)
        let result = plan(events.reversed() + [far], now: now)
        #expect(result.scheduled.map(\.eventID) == events.prefix(3).map(\.id))

        // 8 日先（10/9 12:00）までに始まるものだけ
        let edge = live("ちょうど", day: DomainFixtures.day(2026, 10, 9), at: 15)
        let beyond = live("過ぎる", day: DomainFixtures.day(2026, 10, 9), at: 15, 1)
        #expect(plan([edge], now: now).scheduled.map(\.eventID) == [edge.id])
        #expect(plan([beyond], now: now).scheduled.isEmpty)
    }

    @Test("時間帯を過ぎた予定と、終わった予定は出さない")
    func skipsPastWindows() {
        let today = live(day: DomainFixtures.day(2026, 10, 18), at: 10)
        let ended = live(day: DomainFixtures.day(2026, 10, 10), at: 18)
        let result = plan([today, ended], now: DomainFixtures.date(2026, 10, 18, 12, 0))
        #expect(result.current.isEmpty)
        #expect(result.scheduled.isEmpty)
    }

    @Test("同じ時間帯に複数あれば、開演の早い順にすべて出す")
    func multipleCurrent() {
        let late = live("夜の部", day: DomainFixtures.day(2026, 10, 18), at: 18)
        let early = live("昼の部", day: DomainFixtures.day(2026, 10, 18), at: 16)
        let result = plan([late, early], now: DomainFixtures.date(2026, 10, 18, 15, 30))
        #expect(result.current.map(\.eventID) == [early.id, late.id])
    }

    @Test("開演が 0 時台なら、前の日の夜から出す")
    func windowAcrossMidnight() {
        let event = live(day: DomainFixtures.day(2026, 10, 18), at: 0, 30)
        #expect(plan([event], now: DomainFixtures.date(2026, 10, 17, 21, 30)).current.map(\.eventID) == [event.id])
    }

    @Test("毎年くり返す予定は、その年の回に出す。日付をまたぐ時間帯は、日付が変わっても前の回を出し続ける")
    func repeatingEvents() {
        let birthday = live("誕生日配信", day: DomainFixtures.day(2000, 10, 18), at: 23, 30, repeatsYearly: true)
        let evening = plan([birthday], now: DomainFixtures.date(2026, 10, 18, 21, 0)).current
        #expect(evening.map(\.occurrenceDay) == [DomainFixtures.day(2026, 10, 18)])
        // 10/19 0:10 は、数える回が翌年に移っても、前の回（開演 23:30 の 1 時間後の 0:30 まで）を出す
        let afterMidnight = plan([birthday], now: DomainFixtures.date(2026, 10, 19, 0, 10)).current
        #expect(afterMidnight.map(\.occurrenceDay) == [DomainFixtures.day(2026, 10, 18)])
    }

    @Test("日付と時刻は書いたまま、端末のタイムゾーンで数える")
    func timeZone() {
        let newYork = DomainFixtures.calendar(timeZone: "America/New_York")
        let event = live(day: DomainFixtures.day(2026, 10, 18), at: 17)
        let window = plan([event], now: DomainFixtures.date(2026, 10, 18, 15, 0, calendar: newYork), calendar: newYork).current.first
        #expect(window?.start == DomainFixtures.date(2026, 10, 18, 17, 0, calendar: newYork))
    }

    @Test("中身は推しの名前・タイトル・推し色・開演の時刻と、残りの見出しの文言")
    func attributes() throws {
        let oshi = Oshi(name: "ミナト", color: .navy)
        var event = live("5th LIVE", day: DomainFixtures.day(2026, 10, 18), at: 17)
        event.oshiID = oshi.id
        let window = try #require(plan([event], now: DomainFixtures.date(2026, 10, 18, 15, 0)).current.first)
        let attributes = EventActivityAttributes(window: window, event: event, oshi: oshi, locale: DomainFixtures.japanese)
        #expect(attributes.eventID == event.id)
        #expect(attributes.heading == "ミナト")
        #expect(attributes.title == "5th LIVE")
        #expect(attributes.color == .navy)
        #expect(attributes.startDate == DomainFixtures.date(2026, 10, 18, 17, 0))
        #expect(attributes.countdownBegin == DomainFixtures.date(2026, 10, 18, 14, 0))
        #expect(attributes.untilText == "開演まで")
        #expect(attributes.startText == "開演 17:00")
        #expect(attributes.startedText == "今日は当日！")
        #expect(attributes.link == .eventDetail(event.id))

        let english = EventActivityAttributes(window: window, event: event, oshi: nil, locale: DomainFixtures.english)
        #expect(english.heading == "Live")
        #expect(english.color == .black)
        #expect(english.untilText == "Until showtime")
        #expect(english.startText == "Show 17:00")
    }

    @Test("同じ予定・時刻・文言なら同じ中身になり、置き直しで出し直さない")
    func stableAttributes() throws {
        let event = live(day: DomainFixtures.day(2026, 10, 18), at: 17)
        let first = try #require(plan([event], now: DomainFixtures.date(2026, 10, 18, 15, 0)).current.first)
        let second = try #require(plan([event], now: DomainFixtures.date(2026, 10, 18, 16, 0)).current.first)
        let make = { (window: LiveActivityWindow) in
            EventActivityAttributes(window: window, event: event, oshi: nil, locale: DomainFixtures.japanese)
        }
        #expect(make(first) == make(second))
    }
}
