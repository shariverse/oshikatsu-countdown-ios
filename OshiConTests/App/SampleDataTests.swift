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
    private let countdowns = ["今日！", "あと 3 日", "あと 6 日", "あと 9 日", "あと 12 日", "あと 18 日", "あと 25 日", "あと 32 日"]

    @Test("見本は今日から数えた日付で、先頭はピン留めのライブ。当日の予定と推しなしの予定も入る")
    func sampleSchedule() {
        let sample = SampleData.make(today: today, now: now, language: .japanese)
        let content = HomeContent(events: sample.events, oshis: sample.oshis, selectedOshiID: nil, showsPastEvents: false, today: today)
        #expect(content.featured?.event.title == "ドームツアー 東京公演")
        #expect(content.featured?.event.venue == "東京ドーム")
        #expect(content.featured?.event.startTime == TimeOfDay(hour: 17, minute: 0))
        #expect(content.featured?.countdownText == "あと 12 日")
        #expect(content.upcoming.map(\.countdownText) == countdowns)
        #expect(content.upcoming.contains { $0.oshi == nil })
        #expect(content.past.isEmpty)
        #expect(sample.oshis.map(\.name) == ["LUMINA", "ミナト", "レオ", "レン", "ひなた", "ソラ"])
    }

    @Test("いつ撮っても同じ残り日数になる（年末・うるう年をまたいでも）", arguments: [
        DomainFixtures.day(2026, 12, 30),
        DomainFixtures.day(2028, 2, 26),
        DomainFixtures.day(2027, 2, 26)
    ])
    func stableAcrossDates(day: CalendarDay) {
        let sample = SampleData.make(today: day, now: now, language: .japanese)
        let content = HomeContent(events: sample.events, oshis: sample.oshis, selectedOshiID: nil, showsPastEvents: false, today: day)
        #expect(content.upcoming.map(\.countdownText) == countdowns)
    }

    @Test("どの言語でも同じ構図になる（推し 6 人・推し色はばらばら・ピン留め 1 件・今日の予定 1 件・推しなし 1 件・うるう年の誕生日）",
          arguments: SampleData.Language.allCases)
    func sameShapeInEveryLanguage(language: SampleData.Language) throws {
        let sample = SampleData.make(today: today, now: now, language: language)
        #expect(sample.oshis.count == 6)
        #expect(Set(sample.oshis.map(\.color)).count == sample.oshis.count)
        #expect(sample.oshis.first?.name == "LUMINA")
        #expect(Set(sample.oshis.map(\.name)).count == sample.oshis.count)

        let pinned = sample.events.filter(\.isPinned)
        #expect(pinned.count == 1)
        let live = try #require(pinned.first)
        #expect(live.kind == .live)
        #expect(live.day == today.adding(days: 12))
        #expect(live.startTime != nil)
        #expect(!live.venue.isEmpty)

        #expect(sample.events.filter { $0.occurrence(from: today) == today }.count == 1)
        #expect(sample.events.filter { $0.oshiID == nil }.count == 1)
        let birthdays = sample.events.filter(\.repeatsYearly)
        #expect(birthdays.map(\.kind) == [.birthday])
        #expect(birthdays.map(\.day.year) == [2000])
        // 予定はどれも見本の推しに結び付く（推しなしの 1 件を除く）
        let oshiIDs = Set(sample.oshis.map(\.id))
        #expect(sample.events.allSatisfy { $0.oshiID.map(oshiIDs.contains) ?? true })
    }

    @Test("どの言語でも、名前・タイトル・会場は入力欄の上限に収まり、保存したときと同じ形になっている", arguments: SampleData.Language.allCases)
    func textsFitInputLimits(language: SampleData.Language) {
        let sample = SampleData.make(today: today, now: now, language: language)
        let texts: [(InputField, String)] = sample.oshis.map { (.oshiName, $0.name) }
            + sample.events.map { (.eventTitle, $0.title) }
            + sample.events.filter { !$0.venue.isEmpty }.map { (.eventVenue, $0.venue) }
        for (field, text) in texts {
            #expect(!field.exceedsLimit(text), "\(language): \(text)")
            #expect(field.isValid(text), "\(language): \(text)")
            #expect(field.normalized(text) == text, "\(language): \(text)")
        }
        // 入力欄の上限より短く、iPhone のホームの行で切れない長さにする
        for event in sample.events {
            #expect(event.title.count <= 30, "\(language): \(event.title)")
        }
    }

    @Test("英語以外の言語は、それぞれの言語の予定名になっている", arguments: SampleData.Language.allCases.filter { $0 != .english })
    func localizedTitles(language: SampleData.Language) {
        let english = SampleData.make(today: today, now: now, language: .english)
        let sample = SampleData.make(today: today, now: now, language: language)
        #expect(sample.events.map(\.title) != english.events.map(\.title))
    }

    @Test("端末の言語から見本の言語を選ぶ。用意していない言語は英語", arguments: [
        ("ja", SampleData.Language.japanese),
        ("ja-JP", .japanese),
        ("en-US", .english),
        ("en-GB", .english),
        ("zh-Hans", .simplifiedChinese),
        ("zh-Hans-CN", .simplifiedChinese),
        ("zh-Hant", .traditionalChinese),
        ("zh-Hant-TW", .traditionalChinese),
        ("zh-TW", .traditionalChinese),
        ("zh-HK", .traditionalChinese),
        ("zh-CN", .simplifiedChinese),
        ("ko-KR", .korean),
        ("fr-FR", .french),
        ("fr-CA", .french),
        ("de-DE", .german),
        ("es-ES", .spanish),
        ("es-419", .spanish),
        ("pt-BR", .brazilianPortuguese),
        ("pt-PT", .brazilianPortuguese),
        ("it-IT", .italian),
        ("th-TH", .thai),
        ("id-ID", .indonesian),
        ("vi-VN", .english),
        ("ru", .english)
    ])
    func languageFromLocale(identifier: String, expected: SampleData.Language) {
        #expect(SampleData.Language(Locale(identifier: identifier)) == expected)
    }
}
