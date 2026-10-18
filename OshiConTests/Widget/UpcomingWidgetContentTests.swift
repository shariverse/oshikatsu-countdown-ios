//
//  UpcomingWidgetContentTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct UpcomingWidgetContentTests {
    private let minato = Oshi(name: "ミナト", color: .navy)
    private let today = DomainFixtures.day(2026, 10, 18)

    private func event(_ title: String, oshi: Oshi?, day: CalendarDay) -> OshiEvent {
        OshiEvent(oshiID: oshi?.id, kind: .live, title: title, day: day, createdAt: DomainFixtures.date(2026, 9, 1))
    }

    private func rows(_ content: UpcomingWidgetContent) -> [UpcomingWidgetContent.Row] {
        guard case let .rows(rows) = content else {
            Issue.record("一覧になっていない: \(content)")
            return []
        }
        return rows
    }

    @Test("当日とこれからの予定を近い順に、決めた件数まで。終わった予定は出さない")
    func upcomingRows() {
        let events = [
            event("後", oshi: minato, day: DomainFixtures.day(2026, 11, 1)),
            event("終わった", oshi: minato, day: DomainFixtures.day(2026, 10, 1)),
            event("当日", oshi: nil, day: today),
            event("先", oshi: minato, day: DomainFixtures.day(2026, 10, 21)),
            event("もっと後", oshi: minato, day: DomainFixtures.day(2026, 12, 1))
        ]
        let shown = rows(UpcomingWidgetContent(events: events, oshis: [minato], today: today, maxRows: 3))
        #expect(shown.map(\.title) == ["当日", "先", "後"])
        #expect(shown.map(\.daysText) == ["今日！", "3日", "14日"])
        #expect(shown.map(\.color) == [.black, .navy, .navy])
        #expect(shown[1].accessibilityLabel == "先、あと 3 日")
    }

    @Test("これからの予定が無ければ空の一覧")
    func emptyRows() {
        let ended = [event("終わった", oshi: nil, day: DomainFixtures.day(2026, 10, 1))]
        #expect(UpcomingWidgetContent(events: ended, oshis: [], today: today, maxRows: 4) == .rows([]))
        #expect(UpcomingWidgetContent(events: [event("当日", oshi: nil, day: today)], oshis: [], today: today, maxRows: 0) == .rows([]))
    }

    @Test("推しが見つからない予定は無彩色")
    func missingOshi() {
        let orphan = event("消えた推し", oshi: Oshi(name: "消えた", color: .pink), day: today)
        #expect(rows(UpcomingWidgetContent(events: [orphan], oshis: [minato], today: today, maxRows: 4)).map(\.color) == [.black])
    }
}
