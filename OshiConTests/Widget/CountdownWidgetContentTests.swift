//
//  CountdownWidgetContentTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct CountdownWidgetContentTests {
    private let minato = Oshi(name: "ミナト", color: .navy)
    private let today = DomainFixtures.day(2026, 10, 18)

    private func event(_ title: String, oshi: Oshi?, kind: EventKind = .live, day: CalendarDay, repeatsYearly: Bool = false) -> OshiEvent {
        OshiEvent(
            oshiID: oshi?.id,
            kind: kind,
            title: title,
            day: day,
            repeatsYearly: repeatsYearly,
            createdAt: DomainFixtures.date(2026, 9, 1)
        )
    }

    @Test("選んだ予定は、推しの名前・タイトル・推し色・残り日数")
    func selectedEvent() throws {
        let live = event("5th LIVE", oshi: minato, day: DomainFixtures.day(2026, 10, 21))
        let content = CountdownWidgetContent(
            eventID: live.id, events: [live], oshis: [minato], today: today, locale: DomainFixtures.japanese
        )
        guard case let .event(shown) = content else {
            Issue.record("予定の中身になっていない: \(content)")
            return
        }
        #expect(shown.eventID == live.id)
        #expect(shown.heading == "ミナト")
        #expect(shown.title == "5th LIVE")
        #expect(shown.color == .navy)
        #expect(shown.countdownText == "あと 3 日")
    }

    @Test("推しなしの予定は種類を上に出し、無彩色")
    func eventWithoutOshi() {
        let release = event("2nd シングル", oshi: nil, kind: .release, day: DomainFixtures.day(2026, 10, 25))
        guard case let .event(shown) = CountdownWidgetContent(
            eventID: release.id, events: [release], oshis: [], today: today, locale: DomainFixtures.japanese
        ) else {
            Issue.record("予定の中身になっていない")
            return
        }
        #expect(shown.heading == "発売日")
        #expect(shown.color == .black)
    }

    @Test("当日は「今日！」、終わった予定は「N 日前」、毎年くり返す予定は次の回を数える")
    func countdownStates() {
        let todayEvent = event("当日", oshi: nil, day: today)
        let ended = event("終わった", oshi: nil, day: DomainFixtures.day(2026, 10, 15))
        let birthday = event("誕生日", oshi: nil, kind: .birthday, day: DomainFixtures.day(2000, 10, 17), repeatsYearly: true)
        let texts = [todayEvent, ended, birthday].map { item -> String? in
            guard case let .event(shown) = CountdownWidgetContent(
                eventID: item.id, events: [item], oshis: [], today: today, locale: DomainFixtures.japanese
            ) else {
                return nil
            }
            return shown.countdownText
        }
        #expect(texts == ["今日！", "3 日前", "あと 364 日"])
    }

    @Test("予定を選んでいなければ未選択、選んだ予定が無ければ削除された")
    func notSelectedAndMissing() {
        let live = event("5th LIVE", oshi: minato, day: today)
        #expect(CountdownWidgetContent(
            eventID: nil, events: [live], oshis: [minato], today: today, locale: DomainFixtures.japanese
        ) == .notSelected)
        #expect(CountdownWidgetContent(
            eventID: UUID(), events: [live], oshis: [minato], today: today, locale: DomainFixtures.japanese
        ) == .missing)
    }

    @Test("選べる予定は当日とこれからの予定を近い順。終わった予定は出さない")
    func selectableEvents() {
        let later = event("後", oshi: nil, day: DomainFixtures.day(2026, 11, 1))
        let sooner = event("先", oshi: nil, day: DomainFixtures.day(2026, 10, 20))
        let todayEvent = event("当日", oshi: nil, day: today)
        let ended = event("終わった", oshi: nil, day: DomainFixtures.day(2026, 10, 1))
        let titles = CountdownWidgetContent.selectableEvents([later, ended, sooner, todayEvent], today: today).map(\.title)
        #expect(titles == ["当日", "先", "後"])
    }

    @Test("次の 0:00 を、端末のタイムゾーンで日付が変わる時刻として求める")
    func nextMidnights() {
        let now = DomainFixtures.date(2026, 10, 18, 23, 59)
        let midnights = WidgetTimeline.nextMidnights(after: now, count: 3, calendar: DomainFixtures.tokyo)
        #expect(midnights == [
            DomainFixtures.date(2026, 10, 19),
            DomainFixtures.date(2026, 10, 20),
            DomainFixtures.date(2026, 10, 21)
        ])

        // 夏時間で 0:00 が飛ぶ日も、その日の始まりを返す（サンパウロは 2018/11/4 の 0:00 が 1:00 になった）
        let saoPaulo = DomainFixtures.calendar(timeZone: "America/Sao_Paulo")
        let beforeShift = DomainFixtures.date(2018, 11, 3, 12, 0, calendar: saoPaulo)
        let shifted = WidgetTimeline.nextMidnights(after: beforeShift, count: 1, calendar: saoPaulo)
        #expect(shifted == [DomainFixtures.date(2018, 11, 4, 1, 0, calendar: saoPaulo)])
        #expect(WidgetTimeline.nextMidnights(after: now, count: 0, calendar: DomainFixtures.tokyo).isEmpty)
    }

    @Test("押したときのリンクを作って読み直せる。知らないリンクは読まない")
    func links() throws {
        let id = UUID()
        for link in [WidgetLink.eventDetail(id), .addEvent, .home] {
            #expect(WidgetLink(url: link.url) == link)
        }
        #expect(WidgetLink.eventDetail(id).url.absoluteString == "oshicon://event/\(id.uuidString)")
        #expect(WidgetLink(url: try #require(URL(string: "https://example.com/event/\(id.uuidString)"))) == nil)
        #expect(WidgetLink(url: try #require(URL(string: "oshicon://event/not-a-uuid"))) == nil)
        #expect(WidgetLink(url: try #require(URL(string: "oshicon://unknown"))) == nil)
    }
}
