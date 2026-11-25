//
//  EventDetailContentTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct EventDetailContentTests {
    private let minato = Oshi(name: "ミナト", color: .navy)

    private func event(
        kind: EventKind = .live,
        day: CalendarDay = DomainFixtures.day(2026, 10, 18),
        startTime: TimeOfDay? = TimeOfDay(hour: 17, minute: 0),
        repeatsYearly: Bool = false,
        createdAt: Date = DomainFixtures.date(2026, 9, 2, 17, 0)
    ) -> OshiEvent {
        OshiEvent(
            oshiID: minato.id,
            kind: kind,
            title: "5th LIVE",
            day: day,
            startTime: startTime,
            venue: "東京ドーム",
            repeatsYearly: repeatsYearly,
            createdAt: createdAt
        )
    }

    private func content(_ event: OshiEvent, oshi: Oshi? = nil, now: Date, locale: Locale = DomainFixtures.japanese) -> EventDetailContent {
        EventDetailContent(event: event, oshi: oshi, now: now, calendar: DomainFixtures.tokyo, locale: locale)
    }

    /// タイルの数字（時間・分・秒の順）。
    private func tileNumbers(_ detail: EventDetailContent) -> [String] {
        detail.clockTiles.map(\.number)
    }

    @Test("開始の前は、開始までの見出しと「あと N 日」、時間・分・秒のタイル・読み上げ")
    func beforeStart() {
        let detail = content(event(), oshi: minato, now: DomainFixtures.date(2026, 10, 15, 9, 54, 51))
        #expect(detail.countdown.status == .upcoming)
        #expect(detail.countdownDisplay == .counting)
        #expect(detail.untilLabel == "開演まで")
        #expect(detail.countdown.remainingParts.days == 3)
        #expect(detail.remainingDaysParts == .init(prefix: "あと", number: "3", suffix: "日"))
        #expect(tileNumbers(detail) == ["07", "05", "09"])
        #expect(detail.clockTiles.map(\.label) == ["時間", "分", "秒"])
        #expect(detail.clockTiles.map(\.unit) == [.hours, .minutes, .seconds])
        // 1 秒ごとに進む秒のタイルだけを目立たせる
        #expect(detail.clockTiles.map(\.isLive) == [false, false, true])
        #expect(detail.remainingDescription == "残り 3日 7時間 5分")
        // 読み上げに秒は入れない（毎秒読み上げ直さない）
        #expect(detail.countdownAccessibilityLabel == "開演まで、残り 3日 7時間 5分")
        #expect(detail.oshiName == "ミナト")
        #expect(detail.color == .navy)
    }

    @Test("時刻の無い予定は「当日まで」で、その日の 0:00 までをタイルで数える。日時は日付だけ")
    func withoutStartTime() {
        let detail = content(event(startTime: nil), now: DomainFixtures.date(2026, 10, 17, 23, 0))
        #expect(detail.countdownDisplay == .counting)
        #expect(detail.untilLabel == "当日まで")
        #expect(detail.remainingDaysParts == .init(prefix: "あと", number: "0", suffix: "日"))
        #expect(tileNumbers(detail) == ["01", "00", "00"])
        #expect(detail.dateText == "10月18日(日)")
    }

    @Test("当日の開始の前は、日数の代わりに「今日！」を出し、開始までをタイルで数える")
    func onTheDayBeforeStart() {
        // 日付が変わった直後から、開始の 1 秒前まで
        let midnight = content(event(), now: DomainFixtures.date(2026, 10, 18, 0, 0))
        #expect(midnight.countdownDisplay == .countingOnTheDay)
        #expect(tileNumbers(midnight) == ["17", "00", "00"])

        let detail = content(event(), now: DomainFixtures.date(2026, 10, 18, 16, 18, 33))
        #expect(detail.countdown.status == .upcoming)
        #expect(detail.countdownDisplay == .countingOnTheDay)
        #expect(tileNumbers(detail) == ["00", "41", "27"])
        #expect(detail.countdownAccessibilityLabel == "今日！、開演まで、残り 41分")

        let lastSecond = content(event(), now: DomainFixtures.date(2026, 10, 18, 16, 59, 59))
        #expect(lastSecond.countdownDisplay == .countingOnTheDay)
        #expect(tileNumbers(lastSecond) == ["00", "00", "01"])
    }

    @Test("前日は、残りが 24 時間を切っていても「今日！」にしない（あと 0 日とタイル）")
    func dayBeforeWithinTwentyFourHours() {
        let detail = content(event(), now: DomainFixtures.date(2026, 10, 17, 20, 45, 24))
        #expect(detail.countdown.daysUntil == 1)
        #expect(detail.countdownDisplay == .counting)
        #expect(detail.remainingDaysParts == .init(prefix: "あと", number: "0", suffix: "日"))
        #expect(tileNumbers(detail) == ["20", "14", "36"])
        #expect(detail.countdownAccessibilityLabel == "開演まで、残り 20時間 14分")
    }

    @Test("開始の時刻の呼び名は種類で変わる", arguments: [(EventKind.release, "発売まで"), (.stream, "配信開始まで"), (.birthday, "開始まで")])
    func untilLabelByKind(kind: EventKind, label: String) {
        #expect(content(event(kind: kind), now: DomainFixtures.date(2026, 10, 1)).untilLabel == label)
    }

    @Test("当日の開始を過ぎたら当日、開催日を過ぎたら終わった予定（N 日前）")
    func todayAndEnded() {
        let today = content(event(), now: DomainFixtures.date(2026, 10, 18, 17, 0))
        #expect(today.countdown.status == .today)
        #expect(today.countdownDisplay == .today)
        // 数えないので、タイルは出さない
        #expect(today.clockTiles.isEmpty)

        let ended = content(event(), now: DomainFixtures.date(2026, 10, 21, 9, 0))
        #expect(ended.countdown.status == .ended)
        #expect(ended.countdownDisplay == .ended)
        #expect(ended.clockTiles.isEmpty)
        #expect(ended.daysAgoText == "3 日前")
    }

    @Test("時刻の無い予定は、当日になったら当日（タイルは出さない）")
    func todayWithoutStartTime() {
        let detail = content(event(startTime: nil), now: DomainFixtures.date(2026, 10, 18, 0, 0))
        #expect(detail.countdownDisplay == .today)
        #expect(detail.clockTiles.isEmpty)
    }

    @Test("毎年くり返す予定は、当日を過ぎたら次の回までを数える")
    func repeatingAfterTheDay() {
        let birthday = event(kind: .birthday, day: DomainFixtures.day(2000, 10, 18), startTime: nil, repeatsYearly: true)
        #expect(content(birthday, now: DomainFixtures.date(2026, 10, 18, 9, 0)).countdownDisplay == .today)

        let next = content(birthday, now: DomainFixtures.date(2026, 10, 19, 9, 0))
        #expect(next.countdownDisplay == .counting)
        #expect(next.remainingDaysParts == .init(prefix: "あと", number: "363", suffix: "日"))
        #expect(tileNumbers(next) == ["15", "00", "00"])
    }

    @Test("進み具合は登録した時刻から開始まで。両端の日付と割合")
    func progress() {
        // 9/2 17:00 から 10/18 17:00 まで（46 日）のうち 35 日目
        let detail = content(event(), now: DomainFixtures.date(2026, 10, 7, 17, 0))
        #expect(detail.progressStartText == "登録 9/2")
        #expect(detail.progressEndText == "当日 10/18")
        #expect(detail.progressPercent == 76)
        #expect(detail.progressPercentText == "76% 経過")
        #expect(detail.progressAccessibilityLabel == "登録 9/2、76% 経過、当日 10/18")
    }

    @Test("毎年くり返す予定の進み具合は、前の回のほうが後ならその日から")
    func progressFromPreviousOccurrence() {
        let birthday = event(
            kind: .birthday,
            day: DomainFixtures.day(2000, 10, 18),
            startTime: nil,
            repeatsYearly: true,
            createdAt: DomainFixtures.date(2020, 1, 1)
        )
        let detail = content(birthday, now: DomainFixtures.date(2026, 4, 18))
        #expect(detail.progressStartText == "登録 10/18")
        #expect(detail.progressEndText == "当日 10/18")
        #expect(detail.countdown.occurrenceDay == DomainFixtures.day(2026, 10, 18))
    }

    @Test("日時・会場・くり返しの行。会場は入れてあるときだけ、くり返しは毎年くり返す予定だけ")
    func infoRows() {
        let rows = content(event(), now: DomainFixtures.date(2026, 10, 1)).infoRows
        #expect(rows.map(\.kind) == [.dateTime, .venue])
        #expect(rows.map(\.title) == ["日時", "会場・場所"])
        #expect(rows.map(\.value) == ["10月18日(日) 開演 17:00", "東京ドーム"])
        #expect(rows.map(\.accessibilityLabel) == ["日時、10月18日(日) 開演 17:00", "会場・場所、東京ドーム"])

        var birthday = event(kind: .birthday, day: DomainFixtures.day(2000, 10, 18), startTime: nil, repeatsYearly: true)
        birthday.venue = ""
        let repeating = content(birthday, now: DomainFixtures.date(2026, 4, 18)).infoRows
        #expect(repeating.map(\.kind) == [.dateTime, .repeating])
        #expect(repeating.map(\.title) == ["日時", "くり返し"])
        #expect(repeating.map(\.value) == ["10月18日(日)", "毎年この日を数えます"])
    }

    @Test("日時は日付と開始の時刻。推しなしの予定は「推しなし」と無彩色。削除の確認の本文")
    func texts() {
        let detail = content(event(), now: DomainFixtures.date(2026, 10, 1))
        #expect(detail.dateText == "10月18日(日) 開演 17:00")
        #expect(detail.oshiName == "推しなし")
        #expect(detail.color == .black)
        #expect(detail.deleteMessage == "「5th LIVE」を削除します。元に戻せません。")
    }

    @Test("英語では見出し・残り・進み具合・日時を英語で出す")
    func englishTexts() {
        let detail = content(event(), oshi: minato, now: DomainFixtures.date(2026, 10, 15, 9, 54, 51), locale: DomainFixtures.english)
        #expect(detail.untilLabel == "Until showtime")
        #expect(detail.remainingDescription == "3 days, 7 hours, 5 minutes left")
        #expect(detail.remainingDaysParts == .init(prefix: "", number: "3", suffix: "days left"))
        #expect(detail.clockTiles.map(\.label) == ["hr", "min", "sec"])
        #expect(detail.infoRows.map(\.title) == ["Date & Time", "Venue"])
        #expect(detail.dateText == "Sun, Oct 18 Show 17:00")
        #expect(detail.kindLabel == "Live")
        #expect(detail.progressStartText == "Added 9/2")
        #expect(detail.progressEndText == "Day 10/18")
        #expect(detail.deleteMessage == "\u{201C}5th LIVE\u{201D} will be deleted. This can't be undone.")
        let onTheDay = content(event(), now: DomainFixtures.date(2026, 10, 18, 16, 18, 33), locale: DomainFixtures.english)
        #expect(onTheDay.countdownAccessibilityLabel == "Today!, Until showtime, 41 minutes left")
        let noOshi = content(event(), now: DomainFixtures.date(2026, 10, 21, 9, 0), locale: DomainFixtures.english)
        #expect(noOshi.oshiName == "No oshi")
        #expect(noOshi.daysAgoText == "3 days ago")
    }
}
