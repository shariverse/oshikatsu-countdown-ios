//
//  EventCountdownTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct EventCountdownTests {
    private let calendar = DomainFixtures.tokyo

    @Test("開始の時刻までの残りを日と時:分:秒で")
    func remainingUntilStartTime() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 19), startTime: TimeOfDay(hour: 17, minute: 30))
        let countdown = EventCountdown(event: event, now: DomainFixtures.date(2026, 10, 18, 12, 0, 15), calendar: calendar)
        #expect(countdown.status == .upcoming)
        #expect(countdown.daysUntil == 1)
        #expect(countdown.remainingParts == RemainingParts(29 * 3_600 + 29 * 60 + 45))
        #expect(countdown.remainingParts.days == 1)
        #expect(countdown.remainingParts.hours == 5)
        #expect(countdown.remainingParts.minutes == 29)
        #expect(countdown.remainingParts.seconds == 45)
    }

    @Test("時刻が無ければ開催日の 0:00 まで")
    func remainingUntilMidnight() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 20))
        let countdown = EventCountdown(event: event, now: DomainFixtures.date(2026, 10, 18, 23, 0), calendar: calendar)
        #expect(countdown.status == .upcoming)
        #expect(countdown.remaining == 3_600 + 86_400)
    }

    @Test("当日の開始の時刻の前は、まだ当日ではない")
    func beforeStartOnTheDay() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18), startTime: TimeOfDay(hour: 17, minute: 0))
        let countdown = EventCountdown(event: event, now: DomainFixtures.date(2026, 10, 18, 16, 0), calendar: calendar)
        #expect(countdown.status == .upcoming)
        #expect(countdown.daysUntil == 0)
        #expect(countdown.remaining == 3_600)
    }

    @Test("当日の開始の時刻を過ぎたら当日。残りは 0 で進み具合は 100%")
    func afterStartOnTheDay() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18), startTime: TimeOfDay(hour: 17, minute: 0))
        let countdown = EventCountdown(event: event, now: DomainFixtures.date(2026, 10, 18, 17, 0), calendar: calendar)
        #expect(countdown.status == .today)
        #expect(countdown.remaining == 0)
        #expect(countdown.progress == 1)
    }

    @Test("終わった予定は残り 0、日数は負")
    func ended() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 15))
        let countdown = EventCountdown(event: event, now: DomainFixtures.date(2026, 10, 18, 9, 0), calendar: calendar)
        #expect(countdown.status == .ended)
        #expect(countdown.daysUntil == -3)
        #expect(countdown.remaining == 0)
        #expect(countdown.progress == 1)
    }

    @Test("進み具合は登録した時刻から開始まで")
    func progressFromCreation() {
        let event = DomainFixtures.event(
            day: DomainFixtures.day(2026, 10, 21),
            createdAt: DomainFixtures.date(2026, 10, 1)
        )
        let countdown = EventCountdown(event: event, now: DomainFixtures.date(2026, 10, 11), calendar: calendar)
        #expect(countdown.progress == 0.5)
        #expect(countdown.progressStartDay == DomainFixtures.day(2026, 10, 1))
    }

    @Test("毎年くり返す予定は、前の回の開始のほうが後なら、そこから数える")
    func progressFromPreviousOccurrence() {
        let birthday = DomainFixtures.event(
            day: DomainFixtures.day(2024, 10, 28),
            repeatsYearly: true,
            createdAt: DomainFixtures.date(2024, 5, 1)
        )
        let countdown = EventCountdown(event: birthday, now: DomainFixtures.date(2026, 10, 18), calendar: calendar)
        #expect(countdown.occurrenceDay == DomainFixtures.day(2026, 10, 28))
        #expect(countdown.progressStartDay == DomainFixtures.day(2025, 10, 28))
        let expected = 355.0 / 365.0
        #expect(abs((countdown.progress ?? 0) - expected) < 0.000_001)
    }

    @Test("毎年くり返す予定でも、登録した時刻のほうが後なら、そこから数える")
    func progressFromCreationWhenLaterThanPreviousOccurrence() {
        let birthday = DomainFixtures.event(
            day: DomainFixtures.day(2024, 10, 28),
            repeatsYearly: true,
            createdAt: DomainFixtures.date(2026, 10, 8)
        )
        let countdown = EventCountdown(event: birthday, now: DomainFixtures.date(2026, 10, 18), calendar: calendar)
        #expect(countdown.progressStartDay == DomainFixtures.day(2026, 10, 8))
        #expect(countdown.progress == 0.5)
    }

    @Test("起点が開始より後なら進み具合は求めない")
    func progressIsNilWhenStartIsAfterTarget() {
        let event = DomainFixtures.event(
            day: DomainFixtures.day(2026, 10, 18),
            startTime: TimeOfDay(hour: 12, minute: 0),
            createdAt: DomainFixtures.date(2026, 10, 18, 13, 0)
        )
        let countdown = EventCountdown(event: event, now: DomainFixtures.date(2026, 10, 18, 11, 0), calendar: calendar)
        #expect(countdown.status == .upcoming)
        #expect(countdown.progress == nil)
    }

    @Test("登録より前の時刻でも進み具合は 0 で止める")
    func progressIsClamped() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 30), createdAt: DomainFixtures.date(2026, 10, 20))
        let countdown = EventCountdown(event: event, now: DomainFixtures.date(2026, 10, 18), calendar: calendar)
        #expect(countdown.progress == 0)
    }

    @Test("日付はタイムゾーンで決まる")
    func usesCalendarTimeZone() {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18))
        // 2026-10-17 16:00 UTC は東京では 10/18 1:00（当日）、UTC では 10/17（前の日）
        let now = DomainFixtures.date(2026, 10, 17, 16, 0, calendar: DomainFixtures.calendar(timeZone: "UTC"))
        #expect(EventCountdown(event: event, now: now, calendar: calendar).status == .today)
        let utc = EventCountdown(event: event, now: now, calendar: DomainFixtures.calendar(timeZone: "UTC"))
        #expect(utc.status == .upcoming)
        #expect(utc.remaining == 8 * 3_600)
    }

    @Test("1 秒未満は切り捨てる")
    func remainingPartsRoundsDown() {
        #expect(RemainingParts(59.9) == RemainingParts(59))
        #expect(RemainingParts(86_400) == RemainingParts(86_400.4))
        #expect(RemainingParts(86_400).days == 1)
        #expect(RemainingParts(-5).seconds == 0)
    }
}
