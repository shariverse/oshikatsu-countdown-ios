//
//  OshiConStoreTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftData
import Testing

struct OshiConStoreTests {
    private let container: ModelContainer
    private let store: OshiConStore

    init() throws {
        container = try OshiConStore.makeContainer(inMemory: true)
        store = OshiConStore(context: ModelContext(container))
    }

    private func makeEvent(
        title: String = "ライブ",
        oshiID: Oshi.ID? = nil,
        isPinned: Bool = false,
        createdAt: Date = DomainFixtures.date(2026, 10, 1)
    ) -> OshiEvent {
        OshiEvent(
            oshiID: oshiID,
            kind: .live,
            title: title,
            day: DomainFixtures.day(2026, 10, 18),
            isPinned: isPinned,
            createdAt: createdAt
        )
    }

    @Test("推しは登録した順に読む")
    func oshisInRegistrationOrder() throws {
        try store.save(Oshi(name: "二人目", color: .blue), now: DomainFixtures.date(2026, 10, 2))
        try store.save(Oshi(name: "一人目", color: .pink), now: DomainFixtures.date(2026, 10, 1))
        try store.save(Oshi(name: "三人目", color: .mint, photoFileName: "photo.jpg"), now: DomainFixtures.date(2026, 10, 3))

        let oshis = try store.oshis()
        #expect(oshis.map(\.name) == ["一人目", "二人目", "三人目"])
        #expect(oshis.map(\.color) == [.pink, .blue, .mint])
        #expect(oshis.last?.photoFileName == "photo.jpg")
    }

    @Test("同じ id の推しを保存すると更新し、登録した順は変えない")
    func updateOshi() throws {
        var first = Oshi(name: "ミナト", color: .pink)
        try store.save(first, now: DomainFixtures.date(2026, 10, 1))
        try store.save(Oshi(name: "ルミナ"), now: DomainFixtures.date(2026, 10, 2))

        first.name = "ミナトくん"
        first.color = .navy
        first.photoFileName = "new.jpg"
        try store.save(first, now: DomainFixtures.date(2026, 10, 3))

        let oshis = try store.oshis()
        #expect(oshis.count == 2)
        #expect(oshis.first == first)
    }

    @Test("予定のすべての項目を保存して読み直せる")
    func eventRoundTrip() throws {
        let oshi = Oshi(name: "ミナト")
        try store.save(oshi, now: DomainFixtures.date(2026, 10, 1))
        let event = OshiEvent(
            oshiID: oshi.id,
            kind: .birthday,
            title: "誕生日",
            day: DomainFixtures.day(2024, 2, 29),
            startTime: TimeOfDay(hour: 23, minute: 59),
            venue: "東京ドーム",
            repeatsYearly: true,
            isPinned: true,
            createdAt: DomainFixtures.date(2026, 10, 1, 12, 34, 56)
        )
        try store.save(event)

        #expect(try store.events() == [event])
        #expect(try store.event(id: event.id) == event)
    }

    @Test("同じ id の予定を保存すると更新する。時刻を外すこともできる")
    func updateEvent() throws {
        var event = makeEvent()
        event.startTime = TimeOfDay(hour: 18, minute: 0)
        try store.save(event)

        event.title = "ライブ 2 日目"
        event.startTime = nil
        event.day = DomainFixtures.day(2026, 10, 19)
        try store.save(event)

        #expect(try store.events() == [event])
    }

    @Test("結び付く推しが見つからない予定は「推しなし」で保存する")
    func eventWithMissingOshi() throws {
        let event = makeEvent(oshiID: UUID())
        try store.save(event)
        #expect(try store.event(id: event.id)?.oshiID == nil)
    }

    @Test("ピン留めは 1 件だけ。別の予定をピン留めすると前のピン留めは外れる")
    func onlyOnePinned() throws {
        let first = makeEvent(title: "1", isPinned: true)
        let second = makeEvent(title: "2")
        try store.save(first)
        try store.save(second)
        #expect(try store.events().filter(\.isPinned).map(\.id) == [first.id])

        try store.setPinned(true, eventID: second.id)
        #expect(try store.events().filter(\.isPinned).map(\.id) == [second.id])

        var third = makeEvent(title: "3")
        third.isPinned = true
        try store.save(third)
        #expect(try store.events().filter(\.isPinned).map(\.id) == [third.id])

        try store.setPinned(false, eventID: third.id)
        #expect(try !store.events().contains(where: \.isPinned))
    }

    @Test("ピン留めした予定をもう一度保存しても、ピン留めは残る")
    func resavingPinnedKeepsPin() throws {
        var event = makeEvent(isPinned: true)
        try store.save(event)
        event.title = "変えた"
        try store.save(event)
        #expect(try store.event(id: event.id)?.isPinned == true)
    }

    @Test("推しを削除すると、結び付いた予定も消える。ほかの推しと推しなしの予定は残る")
    func deleteOshiDeletesEvents() throws {
        let minato = Oshi(name: "ミナト", photoFileName: "minato.jpg")
        let lumina = Oshi(name: "ルミナ")
        try store.save(minato, now: DomainFixtures.date(2026, 10, 1))
        try store.save(lumina, now: DomainFixtures.date(2026, 10, 2))
        let minatoEvents = [makeEvent(title: "ミナト 1", oshiID: minato.id), makeEvent(title: "ミナト 2", oshiID: minato.id)]
        let luminaEvent = makeEvent(title: "ルミナ", oshiID: lumina.id)
        let noOshiEvent = makeEvent(title: "推しなし")
        for event in minatoEvents + [luminaEvent, noOshiEvent] {
            try store.save(event)
        }
        #expect(try store.eventCount(oshiID: minato.id) == 2)

        let deleted = try store.deleteOshi(id: minato.id)
        #expect(deleted?.photoFileName == "minato.jpg")
        #expect(try store.oshis().map(\.id) == [lumina.id])
        #expect(Set(try store.events().map(\.title)) == ["ルミナ", "推しなし"])
        #expect(try store.eventCount(oshiID: minato.id) == 0)

        // 別の context（ウィジェットなど）から読んでも消えている
        let other = OshiConStore(context: ModelContext(container))
        #expect(Set(try other.events().map(\.title)) == ["ルミナ", "推しなし"])
    }

    @Test("見つからない推し・予定を消しても何もしない")
    func deleteMissing() throws {
        try store.save(makeEvent())
        #expect(try store.deleteOshi(id: UUID()) == nil)
        try store.deleteEvent(id: UUID())
        try store.setPinned(true, eventID: UUID())
        #expect(try store.events().count == 1)
    }

    @Test("予定を削除する")
    func deleteEvent() throws {
        let kept = makeEvent(title: "残す")
        let removed = makeEvent(title: "消す")
        try store.save(kept)
        try store.save(removed)
        try store.deleteEvent(id: removed.id)
        #expect(try store.events() == [kept])
    }

    @Test("保存した値が壊れている予定は読み飛ばす")
    func skipsCorruptedEvents() throws {
        let context = store.context
        let valid = makeEvent()
        try store.save(valid)
        insertStoredEvent(month: 13, day: 1, startMinutes: nil, into: context)
        insertStoredEvent(month: 2, day: 0, startMinutes: nil, into: context)
        insertStoredEvent(month: 2, day: 1, startMinutes: 24 * 60, into: context)
        try context.save()
        #expect(try store.events() == [valid])
    }

    private func insertStoredEvent(month: Int, day: Int, startMinutes: Int?, into context: ModelContext) {
        context.insert(
            StoredEvent(
                id: UUID(),
                oshi: nil,
                kindRawValue: "live",
                title: "壊れた",
                year: 2026,
                month: month,
                day: day,
                startMinutes: startMinutes,
                venue: "",
                repeatsYearly: false,
                isPinned: false,
                createdAt: .now
            )
        )
    }

    @Test("知らない種類・推し色は、その他・既定の推し色として読む")
    func unknownRawValues() throws {
        let context = store.context
        let oshi = StoredOshi(id: UUID(), name: "推し", colorRawValue: "gold", photoFileName: nil, createdAt: .now)
        context.insert(oshi)
        let event = StoredEvent(
            id: UUID(),
            oshi: oshi,
            kindRawValue: "festival",
            title: "フェス",
            year: 2026,
            month: 10,
            day: 18,
            startMinutes: nil,
            venue: "",
            repeatsYearly: false,
            isPinned: false,
            createdAt: .now
        )
        context.insert(event)
        try context.save()
        #expect(try store.oshis().first?.color == .defaultColor)
        #expect(try store.events().first?.kind == .other)
        #expect(try store.events().first?.oshiID == oshi.id)
    }
}
