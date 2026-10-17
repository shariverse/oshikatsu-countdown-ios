//
//  HomeContentTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct HomeContentTests {
    private let minato = Oshi(name: "ミナト", color: .navy)
    private let lumina = Oshi(name: "ルミナ", color: .pink)
    private let today = DomainFixtures.day(2026, 10, 18)

    private func event(
        _ title: String,
        oshi: Oshi?,
        day: CalendarDay,
        repeatsYearly: Bool = false,
        isPinned: Bool = false
    ) -> OshiEvent {
        OshiEvent(
            oshiID: oshi?.id,
            kind: .live,
            title: title,
            day: day,
            repeatsYearly: repeatsYearly,
            isPinned: isPinned,
            createdAt: DomainFixtures.date(2026, 9, 1)
        )
    }

    private var events: [OshiEvent] {
        [
            event("ミナトのライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 25)),
            event("ルミナのライブ", oshi: lumina, day: DomainFixtures.day(2026, 10, 20), isPinned: true),
            event("推しなしの予定", oshi: nil, day: DomainFixtures.day(2026, 11, 1)),
            event("終わったライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 1))
        ]
    }

    @Test("すべてのときは、ピン留めを先頭に、これからの予定を近い順に出す。終わった予定は設定で出す")
    func allEvents() {
        let hidden = HomeContent(events: events, oshis: [minato, lumina], selectedOshiID: nil, showsPastEvents: false, today: today)
        #expect(hidden.featured?.event.title == "ルミナのライブ")
        #expect(hidden.upcoming.map(\.event.title) == ["ルミナのライブ", "ミナトのライブ", "推しなしの予定"])
        #expect(hidden.past.isEmpty)
        #expect(hidden.emptyState == nil)

        let shown = HomeContent(events: events, oshis: [minato, lumina], selectedOshiID: nil, showsPastEvents: true, today: today)
        #expect(shown.past.map(\.event.title) == ["終わったライブ"])
    }

    @Test("推しで絞り込むと、その推しの予定だけ。先頭はその中で選ぶ")
    func filterByOshi() {
        let content = HomeContent(events: events, oshis: [minato, lumina], selectedOshiID: minato.id, showsPastEvents: true, today: today)
        #expect(content.selectedOshiID == minato.id)
        #expect(content.featured?.event.title == "ミナトのライブ")
        #expect(content.upcoming.map(\.event.title) == ["ミナトのライブ"])
        #expect(content.past.map(\.event.title) == ["終わったライブ"])
    }

    @Test("選んでいた推しが消えたら「すべて」に戻す")
    func removedOshiFallsBackToAll() {
        let content = HomeContent(events: events, oshis: [lumina], selectedOshiID: minato.id, showsPastEvents: false, today: today)
        #expect(content.selectedOshiID == nil)
        #expect(content.upcoming.count == 3)
    }

    @Test("予定が 1 件も無いとき・絞り込んだ推しの予定が無いときの案内")
    func emptyStates() {
        #expect(HomeContent(events: [], oshis: [], selectedOshiID: nil, showsPastEvents: false, today: today).emptyState == .noEvents)
        let others = [event("ルミナのライブ", oshi: lumina, day: DomainFixtures.day(2026, 10, 20))]
        let filtered = HomeContent(events: others, oshis: [minato, lumina], selectedOshiID: minato.id, showsPastEvents: false, today: today)
        #expect(filtered.emptyState == .noEventsForOshi)
        #expect(filtered.featured == nil)
    }

    @Test("終わった予定しか無いときは案内を出さず、これからの予定は空")
    func onlyPastEvents() {
        let past = [event("終わったライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 1))]
        let content = HomeContent(events: past, oshis: [minato], selectedOshiID: nil, showsPastEvents: false, today: today)
        #expect(content.emptyState == nil)
        #expect(content.featured == nil)
        #expect(content.upcoming.isEmpty)
    }

    @Test("行の補足は日付と推しの名前。毎年くり返す予定は「毎年」、推しなしは「推しなし」。色は推し色か無彩色")
    func itemTexts() {
        let items = HomeContent(
            events: [
                event("ライブ", oshi: minato, day: DomainFixtures.day(2026, 10, 25)),
                event("誕生日", oshi: minato, day: DomainFixtures.day(2000, 10, 18), repeatsYearly: true),
                event("推しなし", oshi: nil, day: DomainFixtures.day(2026, 11, 1))
            ],
            oshis: [minato],
            selectedOshiID: nil,
            showsPastEvents: false,
            today: today
        ).upcoming
        #expect(items.map(\.supportingText) == ["10月18日(日) · 毎年", "10月25日(日) · ミナト", "11月1日(日) · 推しなし"])
        #expect(items.map(\.countdownText) == ["今日！", "あと 7 日", "あと 14 日"])
        #expect(items.map(\.color) == [.navy, .navy, .black])
    }

    @Test("推しが見つからない予定は推しなしとして出す")
    func missingOshi() {
        let orphan = event("消えた推しの予定", oshi: Oshi(name: "消えた"), day: DomainFixtures.day(2026, 10, 25))
        let item = HomeContent(events: [orphan], oshis: [minato], selectedOshiID: nil, showsPastEvents: false, today: today).upcoming[0]
        #expect(item.oshi == nil)
        #expect(item.supportingText == "10月25日(日) · 推しなし")
    }
}
