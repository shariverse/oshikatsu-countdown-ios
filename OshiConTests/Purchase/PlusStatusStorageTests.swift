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
        let store = PlusStore(isActive: false, unlocksWhenInactive: false, storage: storage)
        #expect(!store.isUnlocked)
        await store.refresh()
        #expect(!store.isUnlocked)
        #expect(storage.isUnlocked)
    }

    @Test("メモリ上のストアで -plusUnlocked のときは、書いた結果が無くても使えるままで、書き換えない")
    @MainActor
    func inactiveStoreUnlockedByArgument() async throws {
        let storage = try Self.makeStorage()
        let store = PlusStore(isActive: false, unlocksWhenInactive: true, storage: storage)
        #expect(store.isUnlocked)
        await store.refresh()
        #expect(store.isUnlocked)
        #expect(!storage.isUnlocked)
    }

    @Test(
        "起動引数で Plus の状態を固定する。メモリ上のストアのときだけ効き、-plusLocked を優先する",
        arguments: [
            (["-useInMemoryStore", "-plusUnlocked"], true),
            (["-useInMemoryStore", "-plusLocked"], false),
            (["-useInMemoryStore"], false),
            (["-useInMemoryStore", "-plusUnlocked", "-plusLocked"], false),
            (["-plusUnlocked"], false)
        ]
    )
    func unlocksPlusArgument(arguments: [String], expected: Bool) {
        #expect(LaunchOptions.unlocksPlus(arguments: arguments) == expected)
    }

    @Test("テストのホストのアプリ（起動引数なし）は Plus を固定しない")
    func hostAppDoesNotUnlockPlus() {
        #expect(!LaunchOptions.unlocksPlus)
    }
}
