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

    @Test("開始の前は、開始までの見出しと時:分:秒・読み上げ")
    func beforeStart() {
        let detail = content(event(), oshi: minato, now: DomainFixtures.date(2026, 10, 15, 9, 54, 51))
        #expect(detail.countdown.status == .upcoming)
        #expect(detail.untilLabel == "開演まで")
        #expect(detail.countdown.remainingParts.days == 3)
        #expect(detail.clockText == "07:05:09")
        #expect(detail.remainingDescription == "残り 3日 7時間 5分")
        #expect(detail.countdownAccessibilityLabel == "開演まで、残り 3日 7時間 5分")
        #expect(detail.remainingDaysParts == .init(prefix: "", number: "3", suffix: "日"))
        #expect(detail.oshiName == "ミナト")
        #expect(detail.color == .navy)
    }

    @Test("時刻の無い予定は「当日まで」で、その日の 0:00 までを数える。日時は日付だけ")
    func withoutStartTime() {
        let detail = content(event(startTime: nil), now: DomainFixtures.date(2026, 10, 17, 23, 0))
        #expect(detail.untilLabel == "当日まで")
        #expect(detail.clockText == "01:00:00")
        #expect(detail.dateText == "10月18日(日)")
    }

    @Test("開始の時刻の呼び名は種類で変わる", arguments: [(EventKind.release, "発売まで"), (.stream, "配信開始まで"), (.birthday, "開始まで")])
    func untilLabelByKind(kind: EventKind, label: String) {
        #expect(content(event(kind: kind), now: DomainFixtures.date(2026, 10, 1)).untilLabel == label)
    }

    @Test("当日の開始を過ぎたら当日、開催日を過ぎたら終わった予定（N 日前）")
    func todayAndEnded() {
        let today = content(event(), now: DomainFixtures.date(2026, 10, 18, 17, 0))
        #expect(today.countdown.status == .today)
        #expect(today.clockText == "00:00:00")

        let ended = content(event(), now: DomainFixtures.date(2026, 10, 21, 9, 0))
        #expect(ended.countdown.status == .ended)
        #expect(ended.daysAgoText == "3 日前")
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
        #expect(detail.remainingDaysParts == .init(prefix: "", number: "3", suffix: "days"))
        #expect(detail.dateText == "Sun, Oct 18 Show 17:00")
        #expect(detail.kindLabel == "Live")
        #expect(detail.progressStartText == "Added 9/2")
        #expect(detail.progressEndText == "Day 10/18")
        #expect(detail.deleteMessage == "\u{201C}5th LIVE\u{201D} will be deleted. This can't be undone.")
        let noOshi = content(event(), now: DomainFixtures.date(2026, 10, 21, 9, 0), locale: DomainFixtures.english)
        #expect(noOshi.oshiName == "No oshi")
        #expect(noOshi.daysAgoText == "3 days ago")
    }
}
