//
//  ShareCardContentTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct ShareCardContentTests {
    private let minato = Oshi(name: "ミナト", color: .navy, photoFileName: "minato.jpg")

    private func event(
        kind: EventKind = .live,
        day: CalendarDay = DomainFixtures.day(2026, 10, 18),
        startTime: TimeOfDay? = TimeOfDay(hour: 17, minute: 0),
        venue: String = "東京ドーム",
        repeatsYearly: Bool = false
    ) -> OshiEvent {
        OshiEvent(
            oshiID: minato.id,
            kind: kind,
            title: "5th LIVE",
            day: day,
            startTime: startTime,
            venue: venue,
            repeatsYearly: repeatsYearly,
            createdAt: DomainFixtures.date(2020, 1, 1)
        )
    }

    private func birthday(_ day: CalendarDay) -> OshiEvent {
        event(kind: .birthday, day: day, startTime: nil, venue: "", repeatsYearly: true)
    }

    private func content(
        _ event: OshiEvent,
        oshi: Oshi? = nil,
        now: Date,
        calendar: Calendar = DomainFixtures.tokyo,
        options: ShareCardContent.Options = .init(),
        locale: Locale = DomainFixtures.japanese
    ) -> ShareCardContent {
        ShareCardContent(event: event, oshi: oshi, now: now, calendar: calendar, options: options, locale: locale)
    }

    @Test("残りがある予定は、予定名・年まで出す日付・「あと N 日」と推し色")
    func remaining() {
        let card = content(event(), oshi: minato, now: DomainFixtures.date(2026, 10, 15, 9, 0))
        #expect(card.title == "5th LIVE")
        #expect(card.dateText == "2026年10月18日(日)")
        #expect(card.days == .remaining(.init(prefix: "あと", number: "3", suffix: "日")))
        #expect(card.daysText == "あと 3 日")
        #expect(card.color == .navy)
        #expect(card.accessibilityLabel == "5th LIVE、2026年10月18日(日)、あと 3 日")
    }

    @Test("日付の変わり目: 前の日の 23:59:59 は「あと 1 日」、0:00 から当日")
    func dayBoundary() {
        let lastSecond = content(event(), now: DomainFixtures.date(2026, 10, 17, 23, 59, 59))
        #expect(lastSecond.days == .remaining(.init(prefix: "あと", number: "1", suffix: "日")))
        let midnight = content(event(), now: DomainFixtures.date(2026, 10, 18, 0, 0))
        #expect(midnight.days == .today(startTime: "開演 17:00"))
    }

    @Test("プレビューは中身が変わったら書き出し直すので、同じ日のうちは中身を同じにし、日付が変わったら変える")
    func contentChangesOnlyWithDay() {
        let morning = content(event(), now: DomainFixtures.date(2026, 10, 16, 0, 0))
        let lastMinute = content(event(), now: DomainFixtures.date(2026, 10, 16, 23, 59))
        let nextDay = content(event(), now: DomainFixtures.date(2026, 10, 17, 0, 0))
        #expect(morning == lastMinute)
        #expect(lastMinute != nextDay)
        // タイムゾーンを変えて日付が変わったときも変える（東京の 10/17 0:00 は、ロサンゼルスではまだ 10/16）
        let losAngeles = content(
            event(),
            now: DomainFixtures.date(2026, 10, 17, 0, 0),
            calendar: DomainFixtures.calendar(timeZone: "America/Los_Angeles")
        )
        #expect(losAngeles != nextDay)
        #expect(losAngeles == lastMinute)
    }

    @Test("当日は、開始の時刻の前も後も「今日！」と開始の時刻（呼び名は種類で変わる）")
    func todayWithStartTime() {
        let before = content(event(), now: DomainFixtures.date(2026, 10, 18, 9, 0))
        #expect(before.days == .today(startTime: "開演 17:00"))
        #expect(before.daysText == "今日！ 開演 17:00")
        let after = content(event(), now: DomainFixtures.date(2026, 10, 18, 21, 0))
        #expect(after.days == .today(startTime: "開演 17:00"))
        let release = content(event(kind: .release, startTime: TimeOfDay(hour: 0, minute: 0)), now: DomainFixtures.date(2026, 10, 18, 9, 0))
        #expect(release.days == .today(startTime: "発売 0:00"))
    }

    @Test("当日で開始の時刻が無ければ「今日！」だけ")
    func todayWithoutStartTime() {
        let card = content(event(startTime: nil), now: DomainFixtures.date(2026, 10, 18, 12, 0))
        #expect(card.days == .today(startTime: nil))
        #expect(card.daysText == "今日！")
    }

    @Test("終わった予定は、開催日のままの日付と「N 日前」")
    func ended() {
        let card = content(event(), now: DomainFixtures.date(2026, 10, 21, 9, 0))
        #expect(card.dateText == "2026年10月18日(日)")
        #expect(card.days == .ago(.init(prefix: "", number: "3", suffix: "日前")))
        #expect(card.daysText == "3 日前")
        let nextDay = content(event(), now: DomainFixtures.date(2026, 10, 19, 0, 0))
        #expect(nextDay.days == .ago(.init(prefix: "", number: "1", suffix: "日前")))
    }

    @Test("毎年くり返す予定は、年をまたいだ次の回の日付と残り日数")
    func repeatingAcrossYear() {
        let card = content(birthday(DomainFixtures.day(2000, 1, 5)), now: DomainFixtures.date(2026, 12, 30, 12, 0))
        #expect(card.dateText == "2027年1月5日(火)")
        #expect(card.days == .remaining(.init(prefix: "あと", number: "6", suffix: "日")))
        // 過ぎても終わった予定にならず、当日は「今日！」
        let today = content(birthday(DomainFixtures.day(2000, 1, 5)), now: DomainFixtures.date(2027, 1, 5, 23, 0))
        #expect(today.dateText == "2027年1月5日(火)")
        #expect(today.days == .today(startTime: nil))
    }

    @Test(
        "2/29 の毎年くり返す予定は、平年は 2/28、うるう年は 2/29 を数える",
        arguments: [
            (DomainFixtures.date(2027, 2, 1), "2027年2月28日(日)", "あと 27 日"),
            (DomainFixtures.date(2027, 2, 28, 10, 0), "2027年2月28日(日)", "今日！"),
            (DomainFixtures.date(2028, 2, 1), "2028年2月29日(火)", "あと 28 日")
        ]
    )
    func leapDay(now: Date, dateText: String, daysText: String) {
        let card = content(birthday(DomainFixtures.day(2000, 2, 29)), now: now)
        #expect(card.dateText == dateText)
        #expect(card.daysText == daysText)
    }

    @Test("日数は渡した暦のタイムゾーンで数える（東京の 10/18 0:30 は、ロサンゼルスではまだ 10/17）")
    func timeZone() {
        let now = DomainFixtures.date(2026, 10, 18, 0, 30)
        let tokyo = content(event(), now: now)
        #expect(tokyo.days == .today(startTime: "開演 17:00"))
        let losAngeles = content(event(), now: now, calendar: DomainFixtures.calendar(timeZone: "America/Los_Angeles"))
        #expect(losAngeles.days == .remaining(.init(prefix: "あと", number: "1", suffix: "日")))
        #expect(losAngeles.dateText == "2026年10月18日(日)")
    }

    @Test("会場は既定で載せず、切り替えると載せる。会場の無い予定は切り替えを出さない")
    func venue() {
        let now = DomainFixtures.date(2026, 10, 15)
        let hidden = content(event(), now: now)
        #expect(hidden.venueText == nil)
        #expect(hidden.canIncludeVenue)

        let shown = content(event(), now: now, options: .init(includesVenue: true))
        #expect(shown.venueText == "東京ドーム")
        #expect(shown.accessibilityLabel == "5th LIVE、2026年10月18日(日)、あと 3 日、東京ドーム")

        let noVenue = content(event(venue: ""), now: now, options: .init(includesVenue: true))
        #expect(noVenue.venueText == nil)
        #expect(!noVenue.canIncludeVenue)
    }

    @Test("推しの写真は既定で載せ、外すと載せない。写真の無い推し・推しなしの予定は切り替えを出さず、無彩色")
    func photo() {
        let now = DomainFixtures.date(2026, 10, 15)
        let shown = content(event(), oshi: minato, now: now)
        #expect(shown.photoFileName == "minato.jpg")
        #expect(shown.canIncludePhoto)

        let hidden = content(event(), oshi: minato, now: now, options: .init(includesPhoto: false))
        #expect(hidden.photoFileName == nil)
        #expect(hidden.canIncludePhoto)

        let withoutPhoto = content(event(), oshi: Oshi(name: "ソラ", color: .mint), now: now)
        #expect(withoutPhoto.photoFileName == nil)
        #expect(!withoutPhoto.canIncludePhoto)
        #expect(withoutPhoto.color == .mint)

        let noOshi = content(event(), now: now)
        #expect(noOshi.photoFileName == nil)
        #expect(!noOshi.canIncludePhoto)
        #expect(noOshi.color == .black)
    }

    @Test("推しの名前は、どの文言にも載せない")
    func withoutOshiName() {
        let card = content(event(), oshi: minato, now: DomainFixtures.date(2026, 10, 15), options: .init(includesVenue: true))
        let texts = [card.title, card.dateText, card.daysText, card.venueText ?? "", card.watermark, card.accessibilityLabel]
        #expect(!texts.contains { $0.contains(minato.name) })
    }

    @Test("英語では日付・日数を英語で出し、単位は複数形を変える")
    func english() {
        let en = DomainFixtures.english
        let remaining = content(event(), now: DomainFixtures.date(2026, 10, 15), locale: en)
        #expect(remaining.dateText == "Sun, Oct 18, 2026")
        #expect(remaining.days == .remaining(.init(prefix: "", number: "3", suffix: "days left")))
        #expect(remaining.daysText == "3 days left")
        #expect(remaining.watermark == "Oshi Countdown")

        let today = content(event(), now: DomainFixtures.date(2026, 10, 18, 9, 0), locale: en)
        #expect(today.days == .today(startTime: "Show 17:00"))
        #expect(today.daysText == "Today! Show 17:00")

        let ended = content(event(), now: DomainFixtures.date(2026, 10, 19, 9, 0), locale: en)
        #expect(ended.days == .ago(.init(prefix: "", number: "1", suffix: "day ago")))
        #expect(ended.daysText == "1 day ago")
    }

    @Test(
        "透かしは App Store の名前のコロンより前のブランド名（12 言語）",
        arguments: [
            ("en", "Oshi Countdown"),
            ("ja", "推し活カウントダウン"),
            ("zh-Hans", "追星倒计时"),
            ("zh-Hant", "推活倒數"),
            ("ko", "최애 디데이"),
            ("fr", "Oshi Countdown"),
            ("de", "Oshi Countdown"),
            ("es", "Oshi Countdown"),
            ("pt-BR", "Oshi Countdown"),
            ("it", "Oshi Countdown"),
            ("th", "Oshi Countdown"),
            ("id", "Oshi Countdown")
        ]
    )
    func watermark(language: String, brand: String) {
        let locale = Locale(identifier: language)
        #expect(ShareCardContent.watermark(locale: locale) == brand)
        #expect(content(event(), now: DomainFixtures.date(2026, 10, 15), locale: locale).watermark == brand)
    }
}
