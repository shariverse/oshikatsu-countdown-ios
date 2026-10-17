//
//  EventScheduleTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct EventScheduleTests {
    private let today = DomainFixtures.day(2026, 10, 18)

    @Test("今日から見た位置と残り日数")
    func statusAndDays() {
        let upcoming = ScheduledEvent(event: DomainFixtures.event(day: DomainFixtures.day(2026, 10, 20)), today: today)
        #expect(upcoming.status == .upcoming)
        #expect(upcoming.daysUntil == 2)

        let onTheDay = ScheduledEvent(event: DomainFixtures.event(day: today, startTime: TimeOfDay(hour: 9, minute: 0)), today: today)
        #expect(onTheDay.status == .today)
        #expect(onTheDay.daysUntil == 0)

        let ended = ScheduledEvent(event: DomainFixtures.event(day: DomainFixtures.day(2026, 10, 15)), today: today)
        #expect(ended.status == .ended)
        #expect(ended.daysUntil == -3)
    }

    @Test("毎年くり返す予定は終わった予定にならず、次の回を数える")
    func repeatingIsNeverEnded() {
        let birthday = DomainFixtures.event(day: DomainFixtures.day(2000, 10, 17), repeatsYearly: true)
        let scheduled = ScheduledEvent(event: birthday, today: today)
        #expect(scheduled.status == .upcoming)
        #expect(scheduled.occurrenceDay == DomainFixtures.day(2027, 10, 17))
        #expect(scheduled.daysUntil == 364)

        let schedule = EventSchedule(events: [birthday], today: today)
        #expect(schedule.past.isEmpty)
        #expect(schedule.upcoming.map(\.event) == [birthday])
    }

    @Test("これからの予定は近い順。同じ日は終日、時刻の早い順、登録した順")
    func upcomingOrder() {
        let tomorrow = DomainFixtures.day(2026, 10, 19)
        let later = DomainFixtures.event(title: "あさって", day: DomainFixtures.day(2026, 10, 20))
        let evening = DomainFixtures.event(title: "18:00", day: tomorrow, startTime: TimeOfDay(hour: 18, minute: 0))
        let midnight = DomainFixtures.event(title: "0:00", day: tomorrow, startTime: TimeOfDay(hour: 0, minute: 0))
        let allDay = DomainFixtures.event(title: "終日", day: tomorrow, createdAt: DomainFixtures.date(2026, 10, 1))
        let morningFirst = DomainFixtures.event(
            title: "9:00 先に登録",
            day: tomorrow,
            startTime: TimeOfDay(hour: 9, minute: 0),
            createdAt: DomainFixtures.date(2026, 9, 1)
        )
        let morningSecond = DomainFixtures.event(
            title: "9:00 後に登録",
            day: tomorrow,
            startTime: TimeOfDay(hour: 9, minute: 0),
            createdAt: DomainFixtures.date(2026, 9, 2)
        )
        let todayEvent = DomainFixtures.event(title: "今日", day: today)

        let schedule = EventSchedule(
            events: [later, morningSecond, evening, todayEvent, morningFirst, allDay, midnight],
            today: today
        )
        #expect(schedule.upcoming.map(\.event.title) == ["今日", "終日", "0:00", "9:00 先に登録", "9:00 後に登録", "18:00", "あさって"])
    }

    @Test("毎年くり返す予定は、最初の回の日付ではなく次の回の日付で並べる")
    func upcomingOrderWithRepeating() {
        let soon = DomainFixtures.event(title: "10/25", day: DomainFixtures.day(2026, 10, 25))
        let birthday = DomainFixtures.event(title: "誕生日 11/5", day: DomainFixtures.day(2000, 11, 5), repeatsYearly: true)
        let later = DomainFixtures.event(title: "12/1", day: DomainFixtures.day(2026, 12, 1))
        let pastBirthday = DomainFixtures.event(title: "誕生日 10/1", day: DomainFixtures.day(2000, 10, 1), repeatsYearly: true)

        let schedule = EventSchedule(events: [pastBirthday, later, birthday, soon], today: today)
        #expect(schedule.upcoming.map(\.event.title) == ["10/25", "誕生日 11/5", "12/1", "誕生日 10/1"])
        #expect(schedule.upcoming.map(\.occurrenceDay).last == DomainFixtures.day(2027, 10, 1))
        #expect(schedule.featured?.event == soon)
    }

    @Test("ピン留めした毎年くり返す予定は、次の回が遠くても先頭の予定")
    func featuredIsPinnedRepeating() {
        let nearest = DomainFixtures.event(title: "近い", day: DomainFixtures.day(2026, 10, 19))
        let pinnedBirthday = DomainFixtures.event(
            title: "誕生日",
            day: DomainFixtures.day(2000, 5, 1),
            repeatsYearly: true,
            isPinned: true
        )
        let schedule = EventSchedule(events: [nearest, pinnedBirthday], today: today)
        #expect(schedule.featured?.event == pinnedBirthday)
        #expect(schedule.featured?.occurrenceDay == DomainFixtures.day(2027, 5, 1))
    }

    @Test("終わった予定は新しい順で、これからの予定に入らない")
    func pastOrder() {
        let older = DomainFixtures.event(title: "10/1", day: DomainFixtures.day(2026, 10, 1))
        let yesterday = DomainFixtures.day(2026, 10, 17)
        let newerMorning = DomainFixtures.event(title: "10/17 10:00", day: yesterday, startTime: TimeOfDay(hour: 10, minute: 0))
        let newerEvening = DomainFixtures.event(title: "10/17 19:00", day: yesterday, startTime: TimeOfDay(hour: 19, minute: 0))
        let upcoming = DomainFixtures.event(title: "これから", day: DomainFixtures.day(2026, 11, 1))

        let schedule = EventSchedule(events: [older, upcoming, newerMorning, newerEvening], today: today)
        #expect(schedule.past.map(\.event.title) == ["10/17 19:00", "10/17 10:00", "10/1"])
        #expect(schedule.upcoming.map(\.event.title) == ["これから"])
    }

    @Test("先頭の予定は、終わっていないピン留めの予定")
    func featuredIsPinned() {
        let nearest = DomainFixtures.event(title: "近い", day: DomainFixtures.day(2026, 10, 19))
        let pinned = DomainFixtures.event(title: "ピン留め", day: DomainFixtures.day(2026, 12, 1), isPinned: true)
        let schedule = EventSchedule(events: [nearest, pinned], today: today)
        #expect(schedule.featured?.event == pinned)
    }

    @Test("ピン留めの予定が終わっていれば、いちばん近い予定")
    func featuredFallsBackWhenPinnedEnded() {
        let nearest = DomainFixtures.event(title: "近い", day: DomainFixtures.day(2026, 10, 19))
        let farther = DomainFixtures.event(title: "遠い", day: DomainFixtures.day(2026, 12, 1))
        let pinnedEnded = DomainFixtures.event(title: "終わったピン留め", day: DomainFixtures.day(2026, 10, 1), isPinned: true)
        let schedule = EventSchedule(events: [farther, pinnedEnded, nearest], today: today)
        #expect(schedule.featured?.event == nearest)
    }

    @Test("ピン留めが無ければいちばん近い予定、当日の予定も含む")
    func featuredIsNearestIncludingToday() {
        let todayEvent = DomainFixtures.event(title: "今日", day: today)
        let tomorrow = DomainFixtures.event(title: "明日", day: DomainFixtures.day(2026, 10, 19))
        let schedule = EventSchedule(events: [tomorrow, todayEvent], today: today)
        #expect(schedule.featured?.event == todayEvent)
    }

    @Test("これからの予定が無ければ先頭の予定も無い")
    func featuredIsNilWithoutUpcoming() {
        #expect(EventSchedule(events: [], today: today).featured == nil)
        let ended = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 1), isPinned: true)
        #expect(EventSchedule(events: [ended], today: today).featured == nil)
    }
}
