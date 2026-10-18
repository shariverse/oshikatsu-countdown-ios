//
//  EventTextTests.swift
//  OshiConTests
//

@testable import OshiCon
import Testing

struct EventTextTests {
    @Test(
        "日付の書き方（一覧・年まで・バーの両端・先頭のカード）",
        arguments: [
            (DomainFixtures.day(2026, 10, 18), "10月18日(日)", "2026年10月18日(日)", "10/18", "10.18 SUN"),
            (DomainFixtures.day(2027, 1, 1), "1月1日(金)", "2027年1月1日(金)", "1/1", "1.1 FRI"),
            (DomainFixtures.day(2028, 2, 29), "2月29日(火)", "2028年2月29日(火)", "2/29", "2.29 TUE"),
            (DomainFixtures.day(2026, 12, 26), "12月26日(土)", "2026年12月26日(土)", "12/26", "12.26 SAT")
        ]
    )
    func dates(day: CalendarDay, monthDay: String, full: String, short: String, badge: String) {
        #expect(EventText.monthDayWeekday(day) == monthDay)
        #expect(EventText.fullDate(day) == full)
        #expect(EventText.shortDate(day) == short)
        #expect(EventText.dateBadge(day) == badge)
    }

    @Test("読み上げの日付は曜日まで言葉で")
    func spokenDate() {
        #expect(EventText.spokenMonthDayWeekday(DomainFixtures.day(2026, 10, 18)) == "10月18日 日曜日")
        #expect(EventText.spokenMonthDayWeekday(DomainFixtures.day(2027, 1, 1)) == "1月1日 金曜日")
    }

    @Test("時刻は 24 時間表記で、時は 0 を付けず分は 2 桁")
    func time() {
        #expect(EventText.time(TimeOfDay(hour: 17, minute: 0)) == "17:00")
        #expect(EventText.time(TimeOfDay(hour: 9, minute: 5)) == "9:05")
        #expect(EventText.time(TimeOfDay(hour: 0, minute: 0)) == "0:00")
        #expect(EventText.time(TimeOfDay(hour: 23, minute: 59)) == "23:59")
    }

    @Test("開始の時刻の呼び名は種類で変わる")
    func startLabel() {
        let time = TimeOfDay(hour: 17, minute: 0)
        #expect(EventText.startTime(time, kind: .live) == "開演 17:00")
        #expect(EventText.startTime(time, kind: .release) == "発売 17:00")
        #expect(EventText.startTime(time, kind: .stream) == "配信開始 17:00")
        #expect(EventText.startTime(time, kind: .birthday) == "開始 17:00")
        #expect(EventText.startTime(time, kind: .other) == "開始 17:00")
    }

    @Test("残り日数は、これからは「あと N 日」、当日は「今日！」、終わった予定は「N 日前」")
    func countdown() {
        #expect(EventText.countdown(daysUntil: 3, status: .upcoming) == "あと 3 日")
        #expect(EventText.countdown(daysUntil: 0, status: .today) == "今日！")
        #expect(EventText.countdown(daysUntil: -2, status: .ended) == "2 日前")
    }
}
