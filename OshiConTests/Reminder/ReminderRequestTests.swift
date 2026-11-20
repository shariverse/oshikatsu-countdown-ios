//
//  ReminderRequestTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing
import UserNotifications

struct ReminderRequestTests {
    private func reminder(for event: OshiEvent, timing: ReminderTiming = .onTheDay) throws -> PlannedReminder {
        let plan = ReminderPlan(
            events: [event],
            settings: ReminderSettings(isEnabled: true, timings: [timing], timeOfDay: TimeOfDay(hour: 9, minute: 15)),
            now: DomainFixtures.date(2026, 9, 1),
            calendar: DomainFixtures.tokyo
        )
        return try #require(plan.reminders.first)
    }

    private func emptyDefaults() throws -> UserDefaults {
        let suiteName = "ReminderRequestTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("出す日時は、タイムゾーンを入れない西暦の日付と時刻（タイムゾーンを変えても、その土地の同じ時刻に出す）")
    func dateComponents() throws {
        let event = DomainFixtures.event(day: DomainFixtures.day(2026, 10, 18))
        let components = ReminderRequest.dateComponents(of: try reminder(for: event))
        #expect(components.calendar?.identifier == .gregorian)
        #expect(components.timeZone == nil)
        #expect(components.year == 2026)
        #expect(components.month == 10)
        #expect(components.day == 18)
        #expect(components.hour == 9)
        #expect(components.minute == 15)
    }

    @Test("識別子・文面・まとめる単位・押したときのリンク")
    func request() throws {
        let event = DomainFixtures.event(title: "ツアー初日", day: DomainFixtures.day(2026, 10, 18))
        let reminder = try reminder(for: event)
        let text = ReminderContent(reminder: reminder, event: event, oshiName: "ミナト", locale: DomainFixtures.japanese)
        let request = ReminderRequest.make(reminder, content: text)
        #expect(request.identifier == reminder.identifier)
        #expect(request.identifier.hasPrefix(ReminderRequest.identifierPrefix))
        #expect(request.content.title == "ツアー初日")
        #expect(request.content.subtitle == "ミナト")
        #expect(request.content.body == "今日！")
        #expect(request.content.threadIdentifier == event.id.uuidString)
        #expect(ReminderRequest.link(from: request.content.userInfo) == .eventDetail(event.id))
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(!trigger.repeats)
        #expect(trigger.dateComponents.day == 18)
    }

    @Test("リンクの無い通知・知らないリンクは開かない")
    func unknownLink() {
        #expect(ReminderRequest.link(from: [:]) == nil)
        #expect(ReminderRequest.link(from: [ReminderRequest.linkKey: "https://example.com"]) == nil)
        #expect(ReminderRequest.link(from: [ReminderRequest.linkKey: 1]) == nil)
    }

    @Test("設定を書いていなければ、既定（ON・5 つすべて・9:00）")
    func defaultSettings() throws {
        #expect(ReminderSettings(defaults: try emptyDefaults()) == .default)
        #expect(ReminderSettings.default.isEnabled)
        #expect(ReminderSettings.default.timings == Set(ReminderTiming.allCases))
        #expect(ReminderSettings.default.timeOfDay == TimeOfDay(hour: 9, minute: 0))
    }

    @Test("設定画面で書いた値を読む")
    func storedSettings() throws {
        let defaults = try emptyDefaults()
        defaults.set(false, forKey: AppStorageKey.remindersEnabled)
        defaults.set(false, forKey: AppStorageKey.reminderTiming(.thirtyDaysBefore))
        defaults.set(false, forKey: AppStorageKey.reminderTiming(.hourBeforeStart))
        defaults.set(20 * 60 + 30, forKey: AppStorageKey.reminderMinutes)
        let settings = ReminderSettings(defaults: defaults)
        #expect(!settings.isEnabled)
        #expect(settings.timings == [.sevenDaysBefore, .dayBefore, .onTheDay])
        #expect(settings.timeOfDay == TimeOfDay(hour: 20, minute: 30))
    }

    @Test("壊れた時刻は既定の 9:00 にする")
    func invalidStoredTime() throws {
        let defaults = try emptyDefaults()
        defaults.set(24 * 60, forKey: AppStorageKey.reminderMinutes)
        #expect(ReminderSettings(defaults: defaults).timeOfDay == TimeOfDay(hour: 9, minute: 0))
    }

    @Test("0:00 からの分で時刻を作る。1 日の外は nil")
    func timeOfDayFromMinutes() {
        #expect(TimeOfDay(minutesSinceMidnight: 0) == TimeOfDay(hour: 0, minute: 0))
        #expect(TimeOfDay(minutesSinceMidnight: 1_439) == TimeOfDay(hour: 23, minute: 59))
        #expect(TimeOfDay(minutesSinceMidnight: 1_440) == nil)
        #expect(TimeOfDay(minutesSinceMidnight: -1) == nil)
    }
}
