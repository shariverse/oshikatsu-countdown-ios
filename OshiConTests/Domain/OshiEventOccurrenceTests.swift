//
//  OshiEventOccurrenceTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct OshiEventOccurrenceTests {
    @Test("くり返さない予定は、過ぎていても登録した日付のまま")
    func nonRepeatingKeepsDay() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 1))
        #expect(event.occurrence(from: DomainFixtures.day(2026, 10, 18)) == DomainFixtures.day(2026, 10, 1))
    }

    @Test(
        "毎年くり返す予定の開催日",
        arguments: [
            // まだ来ていなければ登録した日付
            (DomainFixtures.day(2027, 3, 1), DomainFixtures.day(2026, 10, 18), DomainFixtures.day(2027, 3, 1)),
            // 今年の同じ日がまだ来ていなければ今年
            (DomainFixtures.day(2020, 12, 24), DomainFixtures.day(2026, 10, 18), DomainFixtures.day(2026, 12, 24)),
            // 今年の同じ日が今日なら今日
            (DomainFixtures.day(2020, 10, 18), DomainFixtures.day(2026, 10, 18), DomainFixtures.day(2026, 10, 18)),
            // 今年の同じ日が過ぎていれば来年
            (DomainFixtures.day(2020, 10, 17), DomainFixtures.day(2026, 10, 18), DomainFixtures.day(2027, 10, 17)),
            // 年をまたぐ
            (DomainFixtures.day(2020, 1, 1), DomainFixtures.day(2026, 12, 31), DomainFixtures.day(2027, 1, 1))
        ]
    )
    func repeatingOccurrence(day: CalendarDay, today: CalendarDay, expected: CalendarDay) {
        let event = DomainFixtures.event(day: day, repeatsYearly: true)
        #expect(event.occurrence(from: today) == expected)
    }

    @Test(
        "2/29 の毎年くり返す予定は、平年には 2/28 に数える",
        arguments: [
            (DomainFixtures.day(2025, 1, 10), DomainFixtures.day(2025, 2, 28)),
            (DomainFixtures.day(2025, 2, 28), DomainFixtures.day(2025, 2, 28)),
            (DomainFixtures.day(2025, 3, 1), DomainFixtures.day(2026, 2, 28)),
            (DomainFixtures.day(2027, 3, 1), DomainFixtures.day(2028, 2, 29)),
            (DomainFixtures.day(2028, 2, 29), DomainFixtures.day(2028, 2, 29))
        ]
    )
    func leapDay(today: CalendarDay, expected: CalendarDay) {
        let event = DomainFixtures.event(day: DomainFixtures.day(2024, 2, 29), repeatsYearly: true)
        #expect(event.occurrence(from: today) == expected)
    }

    @Test("前の回の開催日。くり返さない予定と最初の回は無い")
    func previousOccurrence() {
        let repeating = DomainFixtures.event(day: DomainFixtures.day(2024, 2, 29), repeatsYearly: true)
        #expect(repeating.previousOccurrence(before: DomainFixtures.day(2024, 2, 29)) == nil)
        #expect(repeating.previousOccurrence(before: DomainFixtures.day(2025, 2, 28)) == DomainFixtures.day(2024, 2, 29))
        #expect(repeating.previousOccurrence(before: DomainFixtures.day(2026, 2, 28)) == DomainFixtures.day(2025, 2, 28))

        let once = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18))
        #expect(once.previousOccurrence(before: DomainFixtures.day(2026, 10, 18)) == nil)
    }

    @Test("1 回前が最初の回より前になる日付を渡しても、最初の回より前は返さない")
    func previousOccurrenceIsNotBeforeFirst() {
        let repeating = DomainFixtures.event(day: DomainFixtures.day(2026, 3, 1), repeatsYearly: true)
        #expect(repeating.previousOccurrence(before: DomainFixtures.day(2026, 12, 31)) == nil)
        #expect(repeating.previousOccurrence(before: DomainFixtures.day(2027, 3, 1)) == DomainFixtures.day(2026, 3, 1))
    }
}
