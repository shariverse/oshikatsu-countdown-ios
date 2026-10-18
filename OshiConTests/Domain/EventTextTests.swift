//
//  EventTextTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct EventTextTests {
    private let ja = DomainFixtures.japanese
    private let en = DomainFixtures.english

    @Test(
        "日本語の日付の書き方（一覧・年まで・バーの両端・先頭のカード）",
        arguments: [
            (DomainFixtures.day(2026, 10, 18), "10月18日(日)", "2026年10月18日(日)", "10/18", "10.18 SUN"),
            (DomainFixtures.day(2027, 1, 1), "1月1日(金)", "2027年1月1日(金)", "1/1", "1.1 FRI"),
            (DomainFixtures.day(2028, 2, 29), "2月29日(火)", "2028年2月29日(火)", "2/29", "2.29 TUE"),
            (DomainFixtures.day(2026, 12, 26), "12月26日(土)", "2026年12月26日(土)", "12/26", "12.26 SAT")
        ]
    )
    func japaneseDates(day: CalendarDay, monthDay: String, full: String, short: String, badge: String) {
        #expect(EventText.monthDayWeekday(day, locale: ja) == monthDay)
        #expect(EventText.fullDate(day, locale: ja) == full)
        #expect(EventText.shortDate(day, locale: ja) == short)
        #expect(EventText.dateBadge(day, locale: ja) == badge)
    }

    @Test(
        "英語の日付の書き方",
        arguments: [
            (DomainFixtures.day(2026, 10, 18), "Sun, Oct 18", "Sun, Oct 18, 2026", "10/18", "10.18 SUN"),
            (DomainFixtures.day(2028, 2, 29), "Tue, Feb 29", "Tue, Feb 29, 2028", "2/29", "2.29 TUE")
        ]
    )
    func englishDates(day: CalendarDay, monthDay: String, full: String, short: String, badge: String) {
        #expect(EventText.monthDayWeekday(day, locale: en) == monthDay)
        #expect(EventText.fullDate(day, locale: en) == full)
        #expect(EventText.shortDate(day, locale: en) == short)
        #expect(EventText.dateBadge(day, locale: en) == badge)
    }

    @Test("先頭のカードの日付は、日が先の言語では日を先に出す（曜日は英語の大文字のまま）")
    func dateBadgeDayFirst() {
        let day = DomainFixtures.day(2026, 10, 18)
        #expect(EventText.dateBadge(day, locale: Locale(identifier: "de_DE")) == "18.10 SUN")
        #expect(EventText.dateBadge(day, locale: Locale(identifier: "en_GB")) == "18.10 SUN")
    }

    @Test("日付は locale の暦で書く（タイ語は仏暦）")
    func thaiBuddhistYear() {
        #expect(EventText.fullDate(DomainFixtures.day(2026, 10, 18), locale: Locale(identifier: "th_TH")).contains("2569"))
    }

    @Test("読み上げの日付は曜日まで言葉で")
    func spokenDate() {
        #expect(EventText.spokenMonthDayWeekday(DomainFixtures.day(2026, 10, 18), locale: ja) == "10月18日 日曜日")
        #expect(EventText.spokenMonthDayWeekday(DomainFixtures.day(2027, 1, 1), locale: ja) == "1月1日 金曜日")
        #expect(EventText.spokenMonthDayWeekday(DomainFixtures.day(2026, 10, 18), locale: en) == "Sunday, October 18")
    }

    @Test("時刻は 24 時間表記。日本語は時に 0 を付けず分は 2 桁")
    func time() {
        #expect(EventText.time(TimeOfDay(hour: 17, minute: 0), locale: ja) == "17:00")
        #expect(EventText.time(TimeOfDay(hour: 9, minute: 5), locale: ja) == "9:05")
        #expect(EventText.time(TimeOfDay(hour: 0, minute: 0), locale: ja) == "0:00")
        #expect(EventText.time(TimeOfDay(hour: 23, minute: 59), locale: ja) == "23:59")
        // 英語（米国）は端末が 12 時間表記の地域でも 24 時間表記にする
        #expect(EventText.time(TimeOfDay(hour: 17, minute: 0), locale: en) == "17:00")
    }

    @Test("開始の時刻の呼び名は種類で変わる")
    func startTime() {
        let time = TimeOfDay(hour: 17, minute: 0)
        #expect(EventText.startTime(time, kind: .live, locale: ja) == "開演 17:00")
        #expect(EventText.startTime(time, kind: .release, locale: ja) == "発売 17:00")
        #expect(EventText.startTime(time, kind: .stream, locale: ja) == "配信開始 17:00")
        #expect(EventText.startTime(time, kind: .birthday, locale: ja) == "開始 17:00")
        #expect(EventText.startTime(time, kind: .other, locale: ja) == "開始 17:00")
        #expect(EventText.startTime(time, kind: .live, locale: en) == "Show 17:00")
        #expect(EventText.startTime(time, kind: .other, locale: en) == "Starts 17:00")
    }

    @Test("残りの見出しは、時刻が無ければ「当日まで」、あれば種類ごとの呼び名")
    func untilLabel() {
        #expect(EventText.untilLabel(kind: .live, hasStartTime: false, locale: ja) == "当日まで")
        #expect(EventText.untilLabel(kind: .live, hasStartTime: true, locale: ja) == "開演まで")
        #expect(EventText.untilLabel(kind: .stream, hasStartTime: true, locale: ja) == "配信開始まで")
        #expect(EventText.untilLabel(kind: .live, hasStartTime: true, locale: en) == "Until showtime")
    }

    @Test("残り日数は、これからは「あと N 日」、当日は「今日！」、終わった予定は「N 日前」")
    func countdown() {
        #expect(EventText.countdown(daysUntil: 3, status: .upcoming, locale: ja) == "あと 3 日")
        #expect(EventText.countdown(daysUntil: 0, status: .today, locale: ja) == "今日！")
        #expect(EventText.countdown(daysUntil: -2, status: .ended, locale: ja) == "2 日前")
    }

    @Test("英語の残り日数は単数と複数で単位を変える")
    func englishCountdown() {
        #expect(EventText.countdown(daysUntil: 1, status: .upcoming, locale: en) == "1 day left")
        #expect(EventText.countdown(daysUntil: 3, status: .upcoming, locale: en) == "3 days left")
        #expect(EventText.countdown(daysUntil: 0, status: .today, locale: en) == "Today!")
        #expect(EventText.countdown(daysUntil: -1, status: .ended, locale: en) == "1 day ago")
        #expect(EventText.countdown(daysUntil: -2, status: .ended, locale: en) == "2 days ago")
        #expect(EventText.compactDays(daysUntil: 1, status: .upcoming, locale: en) == "1 day")
        #expect(EventText.compactDays(daysUntil: 14, status: .upcoming, locale: en) == "14 days")
        #expect(EventText.compactDays(daysUntil: 14, status: .upcoming, locale: ja) == "14日")
    }

    @Test("残り日数は数字と前後の文言に分けて、数字だけ大きく出せる")
    func countdownParts() {
        #expect(EventText.countdownParts(days: 12, withPrefix: true, locale: ja) == .init(prefix: "あと", number: "12", suffix: "日"))
        #expect(EventText.countdownParts(days: 12, withPrefix: false, locale: ja) == .init(prefix: "", number: "12", suffix: "日"))
        #expect(EventText.countdownParts(days: 12, withPrefix: true, locale: en) == .init(prefix: "", number: "12", suffix: "days left"))
        #expect(EventText.countdownParts(days: 1, withPrefix: false, locale: en) == .init(prefix: "", number: "1", suffix: "day"))
        let es = Locale(identifier: "es_ES")
        #expect(EventText.countdownParts(days: 3, withPrefix: true, locale: es) == .init(prefix: "Faltan", number: "3", suffix: "días"))
    }

    @Test("読み上げの区切りは言語で変わる")
    func speechSeparator() {
        #expect(EventText.joinedForSpeech(["A", "B"], locale: ja) == "A、B")
        #expect(EventText.joinedForSpeech(["A", "B"], locale: en) == "A, B")
    }
}
