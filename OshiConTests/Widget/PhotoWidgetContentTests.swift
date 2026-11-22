//
//  PhotoWidgetContentTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct PhotoWidgetContentTests {
    private let minato = Oshi(name: "ミナト", color: .navy, photoFileName: "\(UUID().uuidString).jpg")
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

    /// `item` を選んだときの予定の中身。予定の中身にならなければ記録して nil。
    private func eventContent(
        _ item: OshiEvent,
        oshis: [Oshi],
        isPlusUnlocked: Bool = true,
        today: CalendarDay? = nil,
        locale: Locale = DomainFixtures.japanese
    ) -> PhotoWidgetContent.Event? {
        let content = PhotoWidgetContent(
            eventID: item.id, events: [item], oshis: oshis, isPlusUnlocked: isPlusUnlocked, today: today ?? self.today, locale: locale
        )
        guard case let .event(shown) = content else {
            Issue.record("予定の中身になっていない: \(content)")
            return nil
        }
        return shown
    }

    @Test("選んだ予定は、タイトル・推しの名前・推し色・写真のファイル名・残り日数・日付")
    func selectedEvent() throws {
        let live = event("5th LIVE", oshi: minato, day: DomainFixtures.day(2026, 10, 21))
        let shown = try #require(eventContent(live, oshis: [minato]))
        #expect(shown.eventID == live.id)
        #expect(shown.title == "5th LIVE")
        #expect(shown.oshiName == "ミナト")
        #expect(shown.heading == "ミナト")
        #expect(shown.color == .navy)
        #expect(shown.photoFileName == minato.photoFileName)
        #expect(shown.daysUntil == 3)
        #expect(shown.countdownText == "あと 3 日")
        #expect(shown.countdownParts == EventText.CountdownParts(prefix: "あと", number: "3", suffix: "日"))
        #expect(shown.dateText == EventText.monthDayWeekday(DomainFixtures.day(2026, 10, 21), locale: DomainFixtures.japanese))
        #expect(shown.accessibilityLabel.hasPrefix("ミナト、5th LIVE、あと 3 日、"))
    }

    @Test("写真の無い推しはファイル名なしで推し色。推しなしの予定は推しの名前も写真もなく、種類を出して無彩色")
    func withoutPhotoOrOshi() throws {
        let sora = Oshi(name: "ソラ", color: .mint)
        let birthday = event("誕生日", oshi: sora, kind: .birthday, day: DomainFixtures.day(2026, 10, 25))
        let withoutPhoto = try #require(eventContent(birthday, oshis: [sora]))
        #expect(withoutPhoto.photoFileName == nil)
        #expect(withoutPhoto.oshiName == "ソラ")
        #expect(withoutPhoto.color == .mint)

        let release = event("2nd シングル", oshi: nil, kind: .release, day: DomainFixtures.day(2026, 10, 25))
        let withoutOshi = try #require(eventContent(release, oshis: [minato]))
        #expect(withoutOshi.oshiName == nil)
        #expect(withoutOshi.heading == "発売日")
        #expect(withoutOshi.photoFileName == nil)
        #expect(withoutOshi.color == .black)
    }

    @Test("推しが削除された予定は、推しなしと同じに出す")
    func deletedOshi() throws {
        let live = event("5th LIVE", oshi: minato, day: DomainFixtures.day(2026, 10, 21))
        let shown = try #require(eventContent(live, oshis: []))
        #expect(shown.oshiName == nil)
        #expect(shown.heading == "ライブ")
        #expect(shown.photoFileName == nil)
    }

    @Test("当日は「今日！」、終わった予定は「N 日前」、毎年くり返す予定は次の回の日付と日数")
    func countdownStates() throws {
        let todayEvent = try #require(eventContent(event("当日", oshi: nil, day: today), oshis: []))
        #expect(todayEvent.status == .today)
        #expect(todayEvent.countdownText == "今日！")

        let ended = try #require(eventContent(event("終わった", oshi: nil, day: DomainFixtures.day(2026, 10, 15)), oshis: []))
        #expect(ended.status == .ended)
        #expect(ended.countdownText == "3 日前")
        #expect(ended.occurrenceDay == DomainFixtures.day(2026, 10, 15))

        // 年をまたいで次の回を数える。2/29 の誕生日は平年には 2/28
        let birthday = event("誕生日", oshi: nil, kind: .birthday, day: DomainFixtures.day(2000, 2, 29), repeatsYearly: true)
        let nextBirthday = try #require(eventContent(birthday, oshis: [], today: DomainFixtures.day(2026, 12, 31)))
        #expect(nextBirthday.occurrenceDay == DomainFixtures.day(2027, 2, 28))
        #expect(nextBirthday.daysUntil == 59)
    }

    @Test("日付は言語ごとの書き方")
    func dateTextInEnglish() throws {
        let live = event("5th LIVE", oshi: minato, day: DomainFixtures.day(2026, 10, 21))
        let shown = try #require(eventContent(live, oshis: [minato], locale: DomainFixtures.english))
        #expect(shown.dateText == EventText.monthDayWeekday(DomainFixtures.day(2026, 10, 21), locale: DomainFixtures.english))
        #expect(shown.countdownText == "3 days left")
    }

    @Test("Plus が使えれば押すと予定の詳細、使えなければ課金画面のリンク（移り先はその予定）")
    func linkByPlus() throws {
        let live = event("5th LIVE", oshi: minato, day: DomainFixtures.day(2026, 10, 21))
        let unlocked = try #require(eventContent(live, oshis: [minato], isPlusUnlocked: true))
        #expect(unlocked.isPlusUnlocked)
        #expect(unlocked.link == .eventDetail(live.id))
        #expect(PhotoWidgetContent.event(unlocked).link == .eventDetail(live.id))

        // Plus でなくても、選んだ予定と写真は見本として出す
        let locked = try #require(eventContent(live, oshis: [minato], isPlusUnlocked: false))
        #expect(!locked.isPlusUnlocked)
        #expect(locked.photoFileName == minato.photoFileName)
        #expect(locked.countdownText == "あと 3 日")
        #expect(locked.link == .plusPaywall(live.id))
        #expect(PhotoWidgetContent.event(locked).link == .plusPaywall(live.id))
    }

    @Test(
        "予定を選んでいなければ未選択、選んだ予定が無ければ削除された。Plus にかかわらず、押すとアプリを開くだけ",
        arguments: [true, false]
    )
    func notSelectedAndMissing(isPlusUnlocked: Bool) {
        let live = event("5th LIVE", oshi: minato, day: today)
        let notSelected = PhotoWidgetContent(
            eventID: nil, events: [live], oshis: [minato], isPlusUnlocked: isPlusUnlocked, today: today
        )
        let missing = PhotoWidgetContent(
            eventID: UUID(), events: [live], oshis: [minato], isPlusUnlocked: isPlusUnlocked, today: today
        )
        #expect(notSelected == .notSelected)
        #expect(missing == .missing)
        for content in [notSelected, missing, PhotoWidgetContent.unavailable] {
            #expect(content.link == .home)
        }
    }

    @Test("選んでいない・削除された・読めないは、カウントダウンウィジェットと同じに分かれる")
    func sameAsCountdown() {
        let live = event("5th LIVE", oshi: minato, day: today)
        for eventID in [nil, UUID()] {
            let photo = PhotoWidgetContent(
                eventID: eventID, events: [live], oshis: [minato], isPlusUnlocked: true, today: today, locale: DomainFixtures.japanese
            )
            let countdown = CountdownWidgetContent(
                eventID: eventID, events: [live], oshis: [minato], today: today, locale: DomainFixtures.japanese
            )
            switch (photo, countdown) {
            case (.notSelected, .notSelected), (.missing, .missing):
                break
            default:
                Issue.record("カウントダウンと違う: \(photo) / \(countdown)")
            }
        }
    }
}
