//
//  OshiListContentTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct OshiListContentTests {
    private let lumina = Oshi(name: "LUMINA", color: .pink)
    private let minato = Oshi(name: "ミナト", color: .navy)
    private let leo = Oshi(name: "レオ", color: .red)
    private let today = DomainFixtures.day(2026, 10, 18)

    private func event(
        _ title: String,
        oshi: Oshi?,
        day: CalendarDay,
        startTime: TimeOfDay? = nil,
        repeatsYearly: Bool = false,
        isPinned: Bool = false,
        createdAt: Date = DomainFixtures.date(2026, 9, 1)
    ) -> OshiEvent {
        OshiEvent(
            oshiID: oshi?.id,
            kind: repeatsYearly ? .birthday : .live,
            title: title,
            day: day,
            startTime: startTime,
            repeatsYearly: repeatsYearly,
            isPinned: isPinned,
            createdAt: createdAt
        )
    }

    private func makeContent(
        _ events: [OshiEvent],
        oshis: [Oshi]? = nil,
        today: CalendarDay? = nil,
        locale: Locale = DomainFixtures.japanese
    ) -> OshiListContent {
        OshiListContent(oshis: oshis ?? [lumina, minato, leo], events: events, today: today ?? self.today, locale: locale)
    }

    @Test("推しは渡した並びの順で、いちばん上が 1 位。1 位はカード、2 位からは行")
    func order() {
        let content = makeContent([])
        #expect(content.rows.map(\.oshi) == [lumina, minato, leo])
        #expect(content.rows.map(\.rank) == [1, 2, 3])
        #expect(content.top?.oshi == lumina)
        #expect(content.others.map(\.oshi) == [minato, leo])
    }

    @Test("推しがいなければ空。1 人だけなら 1 位だけ")
    func fewOshis() {
        let empty = makeContent([], oshis: [])
        #expect(empty.rows.isEmpty)
        #expect(empty.top == nil)
        #expect(empty.others.isEmpty)
        let single = makeContent([], oshis: [minato])
        #expect(single.top?.oshi == minato)
        #expect(single.others.isEmpty)
    }

    @Test("次の予定は、その推しのこれからの予定のうち、いちばん近いもの。ほかの推しの予定・推しなしの予定は見ない")
    func nextEventIsNearestUpcoming() {
        let content = makeContent([
            event("遠いライブ", oshi: minato, day: DomainFixtures.day(2026, 12, 1)),
            event("近いライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 25)),
            event("ルミナのライブ", oshi: lumina, day: DomainFixtures.day(2026, 10, 20)),
            event("推しなしの予定", oshi: nil, day: DomainFixtures.day(2026, 10, 19))
        ])
        #expect(content.rows.map { $0.nextEvent?.event.title } == ["ルミナのライブ", "近いライブ", nil])
        #expect(content.rows.map { $0.nextEvent?.daysUntil } == [2, 7, nil])
        #expect(content.rows.map(\.eventCount) == [1, 2, 0])
    }

    @Test("当日の予定は次の予定になる。終わった予定は次の予定にならないが、件数には数える")
    func todayAndEnded() {
        let content = makeContent([
            event("今日のライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 18)),
            event("明日のライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 19)),
            event("昨日のライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 17)),
            event("終わったライブ", oshi: leo, day: DomainFixtures.day(2026, 10, 1))
        ])
        let minatoRow = content.rows[1]
        #expect(minatoRow.nextEvent?.event.title == "今日のライブ")
        #expect(minatoRow.nextEvent?.status == .today)
        #expect(minatoRow.eventCount == 3)
        let leoRow = content.rows[2]
        #expect(leoRow.nextEvent == nil)
        #expect(leoRow.eventCount == 1)
    }

    @Test("同じ日の予定は、時刻の無い予定・時刻の早い順・登録した順（ホームのこれからの予定と同じ並び）の先頭")
    func sameDayOrder() {
        let day = DomainFixtures.day(2026, 10, 25)
        let evening = event("夜公演", oshi: minato, day: day, startTime: TimeOfDay(hour: 18, minute: 0))
        let matinee = event("昼公演", oshi: minato, day: day, startTime: TimeOfDay(hour: 13, minute: 0))
        let allDay = event("物販", oshi: minato, day: day)
        #expect(makeContent([evening, matinee]).rows[1].nextEvent?.event.title == "昼公演")
        #expect(makeContent([evening, matinee, allDay]).rows[1].nextEvent?.event.title == "物販")
        // 同じ日・同じ時刻は、登録した順
        let later = event("後から登録", oshi: minato, day: day, createdAt: DomainFixtures.date(2026, 9, 2))
        let earlier = event("先に登録", oshi: minato, day: day, createdAt: DomainFixtures.date(2026, 9, 1))
        #expect(makeContent([later, earlier]).rows[1].nextEvent?.event.title == "先に登録")
    }

    @Test("ピン留めした予定があっても、次の予定はいちばん近い予定")
    func pinnedIsNotPreferred() {
        let content = makeContent([
            event("ピン留めしたライブ", oshi: minato, day: DomainFixtures.day(2026, 12, 1), isPinned: true),
            event("近いライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 25))
        ])
        #expect(content.rows[1].nextEvent?.event.title == "近いライブ")
    }

    @Test("毎年くり返す予定は、過ぎたら次の回を数える。2/29 は平年には 2/28")
    func yearlyEvents() {
        let birthday = event("誕生日", oshi: minato, day: DomainFixtures.day(2000, 10, 17), repeatsYearly: true)
        let next = makeContent([birthday]).rows[1].nextEvent
        #expect(next?.occurrenceDay == DomainFixtures.day(2027, 10, 17))
        #expect(next?.daysUntil == 364)
        let leapDay = event("うるう日の記念日", oshi: minato, day: DomainFixtures.day(2024, 2, 29), repeatsYearly: true)
        #expect(makeContent([leapDay]).rows[1].nextEvent?.occurrenceDay == DomainFixtures.day(2027, 2, 28))
        // 年をまたぐ: 12/31 から見た 1/1 の予定は 1 日後
        let newYear = event("カウントダウンライブ", oshi: minato, day: DomainFixtures.day(2020, 1, 1), repeatsYearly: true)
        let atYearEnd = makeContent([newYear], today: DomainFixtures.day(2026, 12, 31)).rows[1].nextEvent
        #expect(atYearEnd?.occurrenceDay == DomainFixtures.day(2027, 1, 1))
        #expect(atYearEnd?.daysUntil == 1)
    }

    @Test("日付は、渡した暦のタイムゾーンで今の時刻から決める（日付の変わり目・タイムゾーン）")
    func todayFromNowAndCalendar() {
        let live = event("ライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 18))
        let make = { (now: Date, calendar: Calendar) in
            OshiListContent(oshis: [minato], events: [live], now: now, calendar: calendar, locale: DomainFixtures.japanese)
                .rows[0]
                .nextEvent
        }
        // 東京の 10/17 23:59 は前日（あと 1 日）、10/18 0:00 は当日、10/19 0:00 は終わった予定
        #expect(make(DomainFixtures.date(2026, 10, 17, 23, 59), DomainFixtures.tokyo)?.daysUntil == 1)
        #expect(make(DomainFixtures.date(2026, 10, 18, 0, 0), DomainFixtures.tokyo)?.status == .today)
        #expect(make(DomainFixtures.date(2026, 10, 18, 23, 59, 59), DomainFixtures.tokyo)?.status == .today)
        #expect(make(DomainFixtures.date(2026, 10, 19, 0, 0), DomainFixtures.tokyo) == nil)
        // 同じ時刻でも、ホノルルではまだ 10/17（あと 1 日）
        let honolulu = DomainFixtures.calendar(timeZone: "Pacific/Honolulu")
        #expect(make(DomainFixtures.date(2026, 10, 18, 9, 0), honolulu)?.daysUntil == 1)
        #expect(make(DomainFixtures.date(2026, 10, 18, 9, 0), DomainFixtures.tokyo)?.status == .today)
    }

    @Test("次の予定の日付・予定の件数・残り日数・リボンの札の文言。これからの予定が無い推しは、日付と残り日数が無い")
    func texts() {
        let content = makeContent([
            event("5th LIVE", oshi: lumina, day: DomainFixtures.day(2026, 10, 25)),
            event("終わったライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 1))
        ])
        #expect(content.rows.map(\.nextEventDateText) == ["10月25日(日)", nil, nil])
        #expect(content.rows.map(\.eventCountText) == ["予定 1 件", "予定 1 件", "予定 0 件"])
        #expect(content.rows.map(\.countdownText) == ["あと 7 日", nil, nil])
        #expect(content.top?.topRibbonText == "最推し！")
    }

    @Test("読み上げは、行が名前・次の予定・日付・残り日数、1 位の推しのカードが「最推し！」・テーマカラー・名前・次の予定・件数")
    func accessibilityLabels() {
        let content = makeContent([
            event("5th LIVE", oshi: lumina, day: DomainFixtures.day(2026, 10, 25)),
            event("誕生日", oshi: minato, day: DomainFixtures.day(2000, 10, 18), repeatsYearly: true)
        ])
        #expect(content.rows[0].topAccessibilityLabel == "最推し！、テーマカラー、LUMINA、5th LIVE、10月25日 日曜日、あと 7 日、予定 1 件")
        #expect(content.rows[1].accessibilityLabel == "ミナト、誕生日、10月18日 日曜日、今日！")
        #expect(content.rows[2].accessibilityLabel == "レオ、予定 0 件")
        // これからの予定が無い 1 位の推しは、次の予定を読まない
        #expect(makeContent([], oshis: [minato]).rows[0].topAccessibilityLabel == "最推し！、テーマカラー、ミナト、予定 0 件")
    }

    @Test("英語では、日付・件数・残り日数・読み上げの区切りも英語の書き方になる")
    func textsInEnglish() {
        let content = makeContent(
            [event("5th LIVE", oshi: lumina, day: DomainFixtures.day(2026, 10, 25))],
            locale: DomainFixtures.english
        )
        #expect(content.rows[0].nextEventDateText == "Sun, Oct 25")
        #expect(content.rows[0].countdownText == "7 days left")
        #expect(content.rows[0].eventCountText == "1 event")
        #expect(content.rows[1].eventCountText == "0 events")
        let spoken = "Top oshi!, Theme color, LUMINA, 5th LIVE, Sunday, October 25, 7 days left, 1 event"
        #expect(content.rows[0].topAccessibilityLabel == spoken)
    }
}
