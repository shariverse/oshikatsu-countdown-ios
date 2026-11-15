//
//  ReminderContentTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct ReminderContentTests {
    /// 2026-10-18 は日曜日。
    private let liveDay = DomainFixtures.day(2026, 10, 18)

    private func content(
        _ timing: ReminderTiming,
        event: OshiEvent,
        oshiName: String? = "ミナト",
        locale: Locale = DomainFixtures.japanese
    ) throws -> ReminderContent {
        let plan = ReminderPlan(
            events: [event],
            settings: ReminderSettings(isEnabled: true, timings: [timing], timeOfDay: TimeOfDay(hour: 9, minute: 0)),
            now: DomainFixtures.date(2026, 9, 1),
            calendar: DomainFixtures.tokyo
        )
        let reminder = try #require(plan.reminders.first)
        return ReminderContent(reminder: reminder, event: event, oshiName: oshiName, locale: locale)
    }

    private func live(startTime: TimeOfDay? = TimeOfDay(hour: 17, minute: 0)) -> OshiEvent {
        DomainFixtures.event(title: "ツアー初日", day: liveDay, startTime: startTime)
    }

    @Test("タイトルは予定のタイトル、サブタイトルは推しの名前")
    func titleAndSubtitle() throws {
        let text = try content(.thirtyDaysBefore, event: live())
        #expect(text.title == "ツアー初日")
        #expect(text.subtitle == "ミナト")
    }

    @Test("推しなしの予定は、サブタイトルを種類にする")
    func subtitleWithoutOshi() throws {
        #expect(try content(.thirtyDaysBefore, event: live(), oshiName: nil).subtitle == "ライブ")
    }

    @Test("N 日前は残りの日数・開催日・開始の時刻")
    func daysBefore() throws {
        #expect(try content(.thirtyDaysBefore, event: live()).body == "あと 30 日 · 10月18日(日) · 開演 17:00")
        #expect(try content(.sevenDaysBefore, event: live()).body == "あと 7 日 · 10月18日(日) · 開演 17:00")
    }

    @Test("前日は「いよいよ明日！」と開催日")
    func dayBefore() throws {
        #expect(try content(.dayBefore, event: live()).body == "いよいよ明日！ · 10月18日(日) · 開演 17:00")
    }

    @Test("当日と開演 1 時間前は、今日のことなので日付を出さない")
    func onTheDayAndHourBefore() throws {
        #expect(try content(.onTheDay, event: live(startTime: TimeOfDay(hour: 18, minute: 30))).body == "今日！ · 開演 18:30")
        #expect(try content(.hourBeforeStart, event: live()).body == "あと 1 時間 · 開演 17:00")
    }

    @Test("開始の時刻が無ければ、時刻を出さない")
    func withoutStartTime() throws {
        #expect(try content(.dayBefore, event: live(startTime: nil)).body == "いよいよ明日！ · 10月18日(日)")
        #expect(try content(.onTheDay, event: live(startTime: nil)).body == "今日！")
    }

    @Test("開始の時刻の呼び名は種類で変わる")
    func startTimeByKind() throws {
        let release = OshiEvent(
            oshiID: nil,
            kind: .release,
            title: "1st アルバム",
            day: liveDay,
            startTime: TimeOfDay(hour: 10, minute: 0),
            createdAt: DomainFixtures.date(2026, 1, 1)
        )
        let text = try content(.hourBeforeStart, event: release, oshiName: nil)
        #expect(text.subtitle == "発売日")
        #expect(text.body == "あと 1 時間 · 発売 10:00")
    }

    @Test("英語では英語の文言と日付の書き方")
    func english() throws {
        let text = try content(.sevenDaysBefore, event: live(), oshiName: nil, locale: DomainFixtures.english)
        #expect(text.subtitle == "Live")
        #expect(text.body == "7 days left · Sun, Oct 18 · Show 17:00")
        let dayBefore = try content(.dayBefore, event: live(), locale: DomainFixtures.english)
        #expect(dayBefore.body == "Tomorrow's the day! · Sun, Oct 18 · Show 17:00")
        #expect(try content(.hourBeforeStart, event: live(), locale: DomainFixtures.english).body == "1 hour to go · Show 17:00")
    }
}
