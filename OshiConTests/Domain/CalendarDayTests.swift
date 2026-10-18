//
//  CalendarDayTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct CalendarDayTests {
    @Test("月の末日より後の日は末日にそろえる（2/29 は平年に 2/28）")
    func clampsToEndOfMonth() {
        #expect(CalendarDay(year: 2025, month: 2, day: 29) == DomainFixtures.day(2025, 2, 28))
        #expect(CalendarDay(year: 2024, month: 2, day: 29).day == 29)
        #expect(CalendarDay(year: 2026, month: 4, day: 31) == DomainFixtures.day(2026, 4, 30))
        #expect(CalendarDay(year: 1900, month: 2, day: 29).day == 28)
        #expect(CalendarDay(year: 2000, month: 2, day: 29).day == 29)
    }

    @Test("同じ月日の別の年。2/29 は平年に 2/28、うるう年に 2/29")
    func withYear() {
        let leapDay = DomainFixtures.day(2024, 2, 29)
        #expect(leapDay.withYear(2025) == DomainFixtures.day(2025, 2, 28))
        #expect(leapDay.withYear(2028) == DomainFixtures.day(2028, 2, 29))
    }

    @Test(
        "暦の日数を数える",
        arguments: [
            (DomainFixtures.day(2026, 10, 18), DomainFixtures.day(2026, 10, 18), 0),
            (DomainFixtures.day(2026, 10, 17), DomainFixtures.day(2026, 10, 18), 1),
            (DomainFixtures.day(2026, 10, 18), DomainFixtures.day(2026, 10, 17), -1),
            (DomainFixtures.day(2024, 2, 28), DomainFixtures.day(2024, 3, 1), 2),
            (DomainFixtures.day(2025, 2, 28), DomainFixtures.day(2025, 3, 1), 1),
            (DomainFixtures.day(2025, 12, 31), DomainFixtures.day(2026, 1, 1), 1),
            (DomainFixtures.day(2024, 1, 1), DomainFixtures.day(2025, 1, 1), 366),
            (DomainFixtures.day(1969, 12, 31), DomainFixtures.day(1970, 1, 1), 1)
        ]
    )
    func daysUntil(from: CalendarDay, to: CalendarDay, expected: Int) {
        #expect(from.days(until: to) == expected)
    }

    @Test("日付は暦のタイムゾーンで決まる")
    func dayInTimeZone() {
        // 2026-10-17 15:30 UTC は東京では 10/18 0:30
        let instant = DomainFixtures.date(2026, 10, 17, 15, 30, calendar: DomainFixtures.calendar(timeZone: "UTC"))
        #expect(CalendarDay(instant, calendar: DomainFixtures.tokyo) == DomainFixtures.day(2026, 10, 18))
        #expect(CalendarDay(instant, calendar: DomainFixtures.calendar(timeZone: "UTC")) == DomainFixtures.day(2026, 10, 17))
    }

    @Test("端末の暦が和暦でも西暦の年で数える")
    func japaneseCalendarUsesGregorianYear() {
        let japanese = DomainFixtures.calendar(timeZone: "Asia/Tokyo", identifier: .japanese)
        let instant = DomainFixtures.date(2026, 10, 18, 12)
        #expect(CalendarDay(instant, calendar: japanese) == DomainFixtures.day(2026, 10, 18))
        #expect(DomainFixtures.day(2026, 10, 18).date(at: nil, calendar: japanese) == DomainFixtures.date(2026, 10, 18))
    }

    @Test("夏時間で 1 日が 23 時間の日も 1 日と数える")
    func daylightSavingTime() {
        let newYork = DomainFixtures.calendar(timeZone: "America/New_York")
        // 2026-03-08 は夏時間が始まる日
        let before = CalendarDay(DomainFixtures.date(2026, 3, 8, 0, 30, calendar: newYork), calendar: newYork)
        let after = CalendarDay(DomainFixtures.date(2026, 3, 9, 0, 30, calendar: newYork), calendar: newYork)
        #expect(before.days(until: after) == 1)
    }

    @Test("時刻を付けた日時。時刻が無ければ 0:00")
    func dateAtTime() {
        let day = DomainFixtures.day(2026, 10, 18)
        #expect(day.date(at: TimeOfDay(hour: 17, minute: 30), calendar: DomainFixtures.tokyo) == DomainFixtures.date(2026, 10, 18, 17, 30))
        #expect(day.date(at: nil, calendar: DomainFixtures.tokyo) == DomainFixtures.date(2026, 10, 18))
    }

    @Test("日付の大小")
    func comparable() {
        #expect(DomainFixtures.day(2026, 10, 18) < DomainFixtures.day(2026, 10, 19))
        #expect(DomainFixtures.day(2026, 9, 30) < DomainFixtures.day(2026, 10, 1))
        #expect(DomainFixtures.day(2025, 12, 31) < DomainFixtures.day(2026, 1, 1))
    }

    @Test("日付を足すと、月・年・うるう日をまたいで前にも後ろにも進む")
    func addingDays() {
        #expect(DomainFixtures.day(2026, 12, 30).adding(days: 3) == DomainFixtures.day(2027, 1, 2))
        #expect(DomainFixtures.day(2028, 2, 28).adding(days: 1) == DomainFixtures.day(2028, 2, 29))
        #expect(DomainFixtures.day(2026, 3, 1).adding(days: -1) == DomainFixtures.day(2026, 2, 28))
        #expect(DomainFixtures.day(2027, 1, 1).adding(days: -1) == DomainFixtures.day(2026, 12, 31))
        #expect(DomainFixtures.day(2026, 10, 18).adding(days: 0) == DomainFixtures.day(2026, 10, 18))
    }
}
