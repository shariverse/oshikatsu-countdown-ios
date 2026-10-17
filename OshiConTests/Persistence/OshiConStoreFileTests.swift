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

    @Test("保存に失敗したら変更を取り消して投げ、読み直しても元のまま")
    func saveFailureRollsBack() throws {
        let kept = Oshi(name: "残す")
        do {
            let store = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url))))
            try store.save(kept, now: .now)
        }
        let readOnly = OshiConStore(context: ModelContext(try OshiConStore.makeContainer(.file(url), allowsSave: false)))
        #expect(throws: (any Error).self) {
            try readOnly.save(Oshi(name: "保存できない"), now: .now)
        }
        #expect(try readOnly.oshis() == [kept])
        #expect(throws: (any Error).self) {
            try readOnly.deleteOshi(id: kept.id)
        }
        #expect(try readOnly.oshis() == [kept])
    }
}
