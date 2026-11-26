//
//  OshiConStoreFileTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftData
import Testing

/// ファイルに保存するストアのテスト。
struct OshiConStoreFileTests {
    private let url = FileManager.default.temporaryDirectory
        .appending(path: "OshiConStoreFileTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        .appending(path: "OshiCon.store", directoryHint: .notDirectory)

    @Test("ファイルのストアに保存すると、開き直しても残る")
    func persistsAcrossContainers() throws {
        let oshi = Oshi(name: "ミナト", color: .navy)
        let event = OshiEvent(oshiID: oshi.id, kind: .live, title: "ライブ", day: DomainFixtures.day(2026, 11, 1), createdAt: .now)
        do {
            let container = try OshiConStore.makeContainer(.file(url))
            let store = OshiConStore(context: ModelContext(container))
            try store.save(oshi, now: .now)
            try store.save(event)
        }
        let reopened = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
        #expect(try reopened.oshis() == [oshi])
        #expect(try reopened.events() == [event])
    }

    /// 読み取り専用（`allowsSave: false`）で開いたストアは保存で投げるので、それで保存の失敗を起こす。
    @Test("保存に失敗したら変更を取り消して投げ、開き直しても元のまま")
    func saveFailureRollsBack() throws {
        let kept = Oshi(name: "残す")
        do {
            let store = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
            try store.save(kept, now: .now)
        }
        do {
            let readOnly = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url), allowsSave: false)))
            #expect(throws: (any Error).self) {
                try readOnly.save(Oshi(name: "保存できない"), now: .now)
            }
            // 取り消したので、保存していない変更は残らない。
            // 読み取り専用のストアでは、取り消した後の読み直しが環境によって挿入した推しを返すことがある（CI で再現）ため、
            // 読み直しは開き直したストアで確かめる
            #expect(!readOnly.context.hasChanges)
        }
        let reopened = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
        #expect(try reopened.oshis() == [kept])
    }

    @Test("並べ替えた順番は、開き直しても残る")
    func reorderPersistsAcrossContainers() throws {
        let first = Oshi(name: "一人目")
        let second = Oshi(name: "二人目")
        do {
            let store = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
            try store.save(first, now: .now)
            try store.save(second, now: .now)
            try store.reorderOshis([second.id, first.id])
        }
        let reopened = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
        #expect(try reopened.oshis() == [second, first])
    }

    @Test("並べ替えの保存に失敗したら変更を取り消して投げ、開き直しても元の並び")
    func reorderFailureRollsBack() throws {
        let first = Oshi(name: "一人目")
        let second = Oshi(name: "二人目")
        do {
            let store = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
            try store.save(first, now: .now)
            try store.save(second, now: .now)
        }
        do {
            let readOnly = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url), allowsSave: false)))
            #expect(throws: (any Error).self) {
                try readOnly.reorderOshis([second.id, first.id])
            }
            #expect(!readOnly.context.hasChanges)
        }
        let reopened = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
        #expect(try reopened.oshis() == [first, second])
    }

    /// 1.2.0 まで（スキーマの V1）のストアを作る。
    private func makeV1Store(oshis: [(name: String, createdAt: Date)]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let schema = Schema(versionedSchema: OshiConSchemaV1.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        for oshi in oshis {
            let stored = OshiConSchemaV1.StoredOshi(
                id: UUID(),
                name: oshi.name,
                colorRawValue: OshiColor.navy.rawValue,
                photoFileName: nil,
                createdAt: oshi.createdAt
            )
            context.insert(stored)
            context.insert(
                OshiConSchemaV1.StoredEvent(
                    id: UUID(),
                    oshi: stored,
                    kindRawValue: EventKind.live.rawValue,
                    title: "\(oshi.name)のライブ",
                    year: 2026,
                    month: 12,
                    day: 24,
                    startMinutes: 18 * 60,
                    venue: "",
                    repeatsYearly: false,
                    isPinned: false,
                    createdAt: oshi.createdAt
                )
            )
        }
        try context.save()
    }

    @Test("V1 のストアを開くと移行し、推しは登録した順・予定はそのまま残る。移行の後に追加した推しは末尾に並ぶ")
    func migrateFromV1() throws {
        try makeV1Store(oshis: [
            ("二人目", DomainFixtures.date(2026, 10, 2)),
            ("一人目", DomainFixtures.date(2026, 10, 1)),
            ("三人目", DomainFixtures.date(2026, 10, 3))
        ])
        #expect(OshiConStore.needsMigration(storeAt: url))

        do {
            let store = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
            #expect(try store.oshis().map(\.name) == ["一人目", "二人目", "三人目"])
            let events = try store.events()
            #expect(events.count == 3)
            #expect(Set(events.compactMap(\.oshiID)) == Set(try store.oshis().map(\.id)))
            #expect(events.allSatisfy { $0.startTime == TimeOfDay(hour: 18, minute: 0) })

            try store.save(Oshi(name: "四人目"), now: DomainFixtures.date(2026, 9, 1))
            #expect(try store.oshis().map(\.name) == ["一人目", "二人目", "三人目", "四人目"])
        }
        #expect(!OshiConStore.needsMigration(storeAt: url))
    }

    @Test("ストアがまだ無ければ、移行は要らない（今の版で作る）")
    func noStoreNeedsNoMigration() {
        #expect(!OshiConStore.needsMigration(storeAt: url))
    }

    @Test("今の版で作ったストアは、移行が要らない")
    func currentStoreNeedsNoMigration() throws {
        do {
            let store = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
            try store.save(Oshi(name: "ミナト"), now: .now)
        }
        #expect(!OshiConStore.needsMigration(storeAt: url))
    }
}
