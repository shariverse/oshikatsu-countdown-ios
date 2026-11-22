//
//  PhotoWidgetTimelineTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct PhotoWidgetTimelineTests {
    private typealias Moment = PhotoWidgetTimeline.Moment

    /// 10/18 12:00（東京）。
    private let now = DomainFixtures.date(2026, 10, 18, 12, 0)

    private func makePlan(isUnlocked: Bool, expirationDate: Date?) -> PhotoWidgetTimeline.Plan {
        PhotoWidgetTimeline.plan(
            now: now,
            plus: PlusWidgetStatus.Resolution(isUnlocked: isUnlocked, expirationDate: expirationDate),
            midnightCount: 3,
            calendar: DomainFixtures.tokyo
        )
    }

    @Test("Plus でなければ、今と 0:00 のエントリをどれも Plus でない表示にし、最後のエントリの後に作り直す")
    func locked() {
        let plan = makePlan(isUnlocked: false, expirationDate: nil)
        #expect(plan.moments == [
            Moment(date: now, isPlusUnlocked: false),
            Moment(date: DomainFixtures.date(2026, 10, 19), isPlusUnlocked: false),
            Moment(date: DomainFixtures.date(2026, 10, 20), isPlusUnlocked: false),
            Moment(date: DomainFixtures.date(2026, 10, 21), isPlusUnlocked: false)
        ])
        #expect(plan.reloadDate == nil)
    }

    @Test("買い切り（期限なし）は、今と 0:00 のエントリをどれも Plus の表示にする")
    func lifetime() {
        let plan = makePlan(isUnlocked: true, expirationDate: nil)
        #expect(plan.moments.map(\.date) == [
            now,
            DomainFixtures.date(2026, 10, 19),
            DomainFixtures.date(2026, 10, 20),
            DomainFixtures.date(2026, 10, 21)
        ])
        #expect(plan.moments.allSatisfy { $0.isPlusUnlocked })
        #expect(plan.reloadDate == nil)
    }

    @Test("期限がエントリの範囲の中にあれば、期限の時刻にもエントリを置いて期限から Plus でない表示にし、期限の時刻に作り直す")
    func expirationWithinTimeline() {
        let expiration = DomainFixtures.date(2026, 10, 19, 15, 30)
        let plan = makePlan(isUnlocked: true, expirationDate: expiration)
        #expect(plan.moments == [
            Moment(date: now, isPlusUnlocked: true),
            Moment(date: DomainFixtures.date(2026, 10, 19), isPlusUnlocked: true),
            Moment(date: expiration, isPlusUnlocked: false),
            Moment(date: DomainFixtures.date(2026, 10, 20), isPlusUnlocked: false),
            Moment(date: DomainFixtures.date(2026, 10, 21), isPlusUnlocked: false)
        ])
        #expect(plan.reloadDate == expiration)
    }

    @Test("期限が 0:00 ちょうどなら、エントリを重ねず、その 0:00 から Plus でない表示にする")
    func expirationAtMidnight() {
        let expiration = DomainFixtures.date(2026, 10, 20)
        let plan = makePlan(isUnlocked: true, expirationDate: expiration)
        #expect(plan.moments == [
            Moment(date: now, isPlusUnlocked: true),
            Moment(date: DomainFixtures.date(2026, 10, 19), isPlusUnlocked: true),
            Moment(date: expiration, isPlusUnlocked: false),
            Moment(date: DomainFixtures.date(2026, 10, 21), isPlusUnlocked: false)
        ])
        #expect(plan.reloadDate == expiration)
    }

    @Test("期限が最後の 0:00 ちょうどでも、期限の時刻に作り直す")
    func expirationAtLastMidnight() {
        let expiration = DomainFixtures.date(2026, 10, 21)
        let plan = makePlan(isUnlocked: true, expirationDate: expiration)
        #expect(plan.moments.count == 4)
        #expect(plan.moments.last == Moment(date: expiration, isPlusUnlocked: false))
        #expect(plan.moments.dropLast().allSatisfy { $0.isPlusUnlocked })
        #expect(plan.reloadDate == expiration)
    }

    @Test("期限がエントリの範囲より後なら、期限のエントリは置かず、最後のエントリの後に作り直す（その時に期限のエントリを置く）")
    func expirationAfterTimeline() {
        let plan = makePlan(isUnlocked: true, expirationDate: DomainFixtures.date(2026, 10, 21, 0, 0, 1))
        #expect(plan.moments.map(\.date) == [
            now,
            DomainFixtures.date(2026, 10, 19),
            DomainFixtures.date(2026, 10, 20),
            DomainFixtures.date(2026, 10, 21)
        ])
        #expect(plan.moments.allSatisfy { $0.isPlusUnlocked })
        #expect(plan.reloadDate == nil)
    }

    @Test("期限をもう過ぎていたら（確かめ直した結果と食い違うとき）、今から Plus でない表示にする")
    func expirationInPast() {
        let plan = makePlan(isUnlocked: true, expirationDate: now)
        #expect(plan.moments.allSatisfy { !$0.isPlusUnlocked })
        #expect(plan.reloadDate == nil)
    }

    @Test("タイムゾーンを変えると、その地域の 0:00 にエントリを置く")
    func timeZone() {
        let newYork = DomainFixtures.calendar(timeZone: "America/New_York")
        let plan = PhotoWidgetTimeline.plan(
            now: now,
            plus: PlusWidgetStatus.Resolution(isUnlocked: true, expirationDate: nil),
            midnightCount: 1,
            calendar: newYork
        )
        // 東京の 10/18 12:00 はニューヨークの 10/17 23:00
        #expect(plan.moments.map(\.date) == [now, DomainFixtures.date(2026, 10, 18, calendar: newYork)])
    }
}
