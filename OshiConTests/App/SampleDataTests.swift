//
//  SampleDataTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct SampleDataTests {
    private let today = DomainFixtures.day(2026, 10, 18)
    private let now = DomainFixtures.date(2026, 10, 18, 9, 41)

    @Test("見本は今日から数えた日付で、先頭はピン留めのライブ。当日の予定と推しなしの予定も入る")
    func sampleSchedule() {
        let sample = SampleData.make(today: today, now: now)
        let content = HomeContent(events: sample.events, oshis: sample.oshis, selectedOshiID: nil, showsPastEvents: false, today: today)
        #expect(content.featured?.event.title == "5th LIVE 東京公演")
        #expect(content.featured?.countdownText == "あと 12 日")
        #expect(content.upcoming.map(\.countdownText) == ["今日！", "あと 3 日", "あと 6 日", "あと 12 日", "あと 25 日"])
        #expect(content.upcoming.contains { $0.oshi == nil })
        #expect(content.past.isEmpty)
        #expect(sample.oshis.map(\.name) == ["LUMINA", "ミナト", "ソラ", "ひなた"])
    }

    @Test("いつ撮っても同じ残り日数になる（年末・うるう年をまたいでも）", arguments: [
        DomainFixtures.day(2026, 12, 30),
        DomainFixtures.day(2028, 2, 26),
        DomainFixtures.day(2027, 2, 26)
    ])
    func stableAcrossDates(day: CalendarDay) {
        let sample = SampleData.make(today: day, now: now)
        let content = HomeContent(events: sample.events, oshis: sample.oshis, selectedOshiID: nil, showsPastEvents: false, today: day)
        #expect(content.upcoming.map(\.countdownText) == ["今日！", "あと 3 日", "あと 6 日", "あと 12 日", "あと 25 日"])
    }
}
