//
//  EventFormTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct EventFormTests {
    private let minato = Oshi(name: "ミナト", color: .navy)
    private let lumina = Oshi(name: "ルミナ", color: .pink)
    private let today = DomainFixtures.day(2026, 10, 18)
    private let now = DomainFixtures.date(2026, 10, 18, 9, 30)

    private func makeEvent(oshiID: Oshi.ID?, kind: EventKind = .release, isPinned: Bool = true) -> OshiEvent {
        OshiEvent(
            oshiID: oshiID,
            kind: kind,
            title: "2nd シングル",
            day: DomainFixtures.day(2026, 12, 24),
            startTime: TimeOfDay(hour: 10, minute: 0),
            venue: "オンライン",
            repeatsYearly: false,
            isPinned: isPinned,
            createdAt: DomainFixtures.date(2026, 9, 2)
        )
    }

    @Test("追加では今日・ライブ・先頭の推しを選んでおき、ほかは空")
    func newEventDefaults() {
        let form = EventForm(event: nil, oshis: [minato, lumina], today: today)
        #expect(form.oshiID == minato.id)
        #expect(form.kind == .live)
        #expect(form.day == today)
        #expect(form.title.isEmpty)
        #expect(form.startTime == nil)
        #expect(form.venue.isEmpty)
        #expect(!form.repeatsYearly)
        #expect(!form.canSave)
    }

    @Test("追加で推しがいなければ「推しなし」")
    func newEventWithoutOshi() {
        #expect(EventForm(event: nil, oshis: [], today: today).oshiID == nil)
    }

    @Test("追加で選んでおく推しを渡すとその推し。登録した推しに無ければ先頭の推し")
    func preselectedOshi() {
        #expect(EventForm(event: nil, oshis: [minato, lumina], today: today, preselectedOshiID: lumina.id).oshiID == lumina.id)
        #expect(EventForm(event: nil, oshis: [minato, lumina], today: today, preselectedOshiID: UUID()).oshiID == minato.id)
    }

    @Test("編集では予定の中身から始める。結び付いた推しが見つからなければ「推しなし」")
    func editingEvent() {
        let event = makeEvent(oshiID: lumina.id)
        let form = EventForm(event: event, oshis: [minato, lumina], today: today)
        #expect(form.oshiID == lumina.id)
        #expect(form.kind == .release)
        #expect(form.title == "2nd シングル")
        #expect(form.day == event.day)
        #expect(form.startTime == TimeOfDay(hour: 10, minute: 0))
        #expect(form.venue == "オンライン")
        #expect(form.canSave)

        #expect(EventForm(event: makeEvent(oshiID: UUID()), oshis: [minato], today: today).oshiID == nil)
    }

    @Test("誕生日を選ぶと毎年くり返すを ON、ほかの種類を選ぶと OFF。同じ種類を選び直しても変えない")
    func selectKindTogglesRepeat() {
        var form = EventForm(event: nil, oshis: [], today: today)
        form.selectKind(.birthday)
        #expect(form.repeatsYearly)
        form.repeatsYearly = false
        form.selectKind(.birthday)
        #expect(!form.repeatsYearly)
        form.selectKind(.stream)
        #expect(!form.repeatsYearly)
        form.repeatsYearly = true
        form.selectKind(.other)
        #expect(!form.repeatsYearly)
        #expect(form.kind == .other)
    }

    @Test(
        "タイトルは必須で 40 文字まで、会場は任意で 40 文字まで",
        arguments: [
            ("ライブ", "", true),
            ("　 ", "", false),
            (String(repeating: "あ", count: 40), String(repeating: "い", count: 40), true),
            (String(repeating: "あ", count: 41), "", false),
            ("ライブ", String(repeating: "い", count: 41), false),
            (String(repeating: "👨‍👩‍👧", count: 40), "", true)
        ]
    )
    func titleAndVenueRules(title: String, venue: String, canSave: Bool) {
        var form = EventForm(event: nil, oshis: [], today: today)
        form.title = title
        form.venue = venue
        #expect(form.canSave == canSave)
    }

    @Test("追加で保存する予定は、渡した id と今の時刻で作り、空白を潰す。ピン留めしない")
    func makeNewEvent() throws {
        var form = EventForm(event: nil, oshis: [minato], today: today)
        form.title = "  5th   LIVE  "
        form.venue = " 東京  ドーム "
        form.startTime = EventForm.defaultStartTime
        let id = UUID()
        let event = try #require(form.makeEvent(existing: nil, newEventID: id, now: now))
        #expect(event.id == id)
        #expect(event.oshiID == minato.id)
        #expect(event.title == "5th LIVE")
        #expect(event.venue == "東京 ドーム")
        #expect(event.day == today)
        #expect(event.startTime == TimeOfDay(hour: 18, minute: 0))
        #expect(!event.isPinned)
        #expect(event.createdAt == now)
    }

    @Test("編集で保存する予定は、id・ピン留め・登録した時刻を引き継ぐ")
    func makeEditedEvent() throws {
        let existing = makeEvent(oshiID: minato.id, isPinned: true)
        var form = EventForm(event: existing, oshis: [minato], today: today)
        form.oshiID = nil
        form.startTime = nil
        let event = try #require(form.makeEvent(existing: existing, newEventID: UUID(), now: now))
        #expect(event.id == existing.id)
        #expect(event.isPinned)
        #expect(event.createdAt == existing.createdAt)
        #expect(event.oshiID == nil)
        #expect(event.startTime == nil)
    }

    @Test("保存できない入力では予定を作らない")
    func invalidFormMakesNoEvent() {
        let form = EventForm(event: nil, oshis: [], today: today)
        #expect(form.makeEvent(existing: nil, newEventID: UUID(), now: now) == nil)
    }
}
