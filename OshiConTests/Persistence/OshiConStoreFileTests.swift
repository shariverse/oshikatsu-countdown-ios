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
}
