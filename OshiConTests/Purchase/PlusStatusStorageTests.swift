//
//  PlusStatusStorageTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct PlusStatusStorageTests {
    /// テストごとの UserDefaults（App Group や端末の設定を書き換えない）。
    private static func makeStorage() throws -> PlusStatusStorage {
        let suiteName = "PlusStatusStorageTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return PlusStatusStorage(defaults: defaults)
    }

    @Test("書いたことが無ければ使えない。書いた結果を読める")
    func readWrite() throws {
        let storage = try Self.makeStorage()
        #expect(!storage.isUnlocked)
        storage.isUnlocked = true
        #expect(storage.isUnlocked)
        #expect(PlusStatusStorage(defaults: storage.defaults).isUnlocked)
        storage.isUnlocked = false
        #expect(!storage.isUnlocked)
    }

    @Test("アプリと Widget Extension は App Group の UserDefaults で受け渡す")
    func appGroupDefaults() throws {
        let identifier = try #require(AppGroupContainer.identifier)
        let shared = try #require(UserDefaults(suiteName: identifier))
        let key = "PlusStatusStorageTests.probe"
        defer { shared.removeObject(forKey: key) }
        PlusStatusStorage.appGroup.defaults.set(true, forKey: key)
        #expect(shared.bool(forKey: key))
    }

    @Test("メモリ上のストアのとき（StoreKit に触れない）は、書いた結果があっても使えないままで、書き換えない")
    @MainActor
    func inactiveStore() async throws {
        let storage = try Self.makeStorage()
        storage.isUnlocked = true
        let store = PlusStore(isActive: false, storage: storage)
        #expect(!store.isUnlocked)
        await store.refresh()
        #expect(!store.isUnlocked)
        #expect(storage.isUnlocked)
    }
}
