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

    @Test("期限は書いたことが無ければ nil。書いた期限を読め、nil を書くと消える")
    func expirationReadWrite() throws {
        let storage = try Self.makeStorage()
        #expect(storage.expirationDate == nil)
        let date = DomainFixtures.date(2026, 11, 21, 12, 0)
        storage.expirationDate = date
        #expect(storage.expirationDate == date)
        #expect(PlusStatusStorage(defaults: storage.defaults).expirationDate == date)
        storage.expirationDate = nil
        #expect(storage.expirationDate == nil)
        #expect(storage.defaults.object(forKey: PlusStatusStorage.expirationDateKey) == nil)
    }

    @Test("結果と期限を書き、どちらかが変わったときだけ変わったと返す")
    func writeReportsChange() throws {
        let storage = try Self.makeStorage()
        let date = DomainFixtures.date(2026, 11, 21, 12, 0)
        #expect(!storage.write(isUnlocked: false, expirationDate: nil))
        #expect(storage.write(isUnlocked: true, expirationDate: date))
        #expect(storage.isUnlocked)
        #expect(storage.expirationDate == date)
        #expect(!storage.write(isUnlocked: true, expirationDate: date))
        // 更新で期限だけ延びたときも描き直す
        let renewed = date.addingTimeInterval(30 * 24 * 3_600)
        #expect(storage.write(isUnlocked: true, expirationDate: renewed))
        #expect(storage.expirationDate == renewed)
        // 買い切りに変わったとき（期限が無くなる）も描き直す
        #expect(storage.write(isUnlocked: true, expirationDate: nil))
        #expect(storage.expirationDate == nil)
        #expect(storage.write(isUnlocked: false, expirationDate: nil))
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
        let date = DomainFixtures.date(2026, 11, 21, 12, 0)
        storage.isUnlocked = true
        storage.expirationDate = date
        let store = PlusStore(isActive: false, unlocksWhenInactive: false, storage: storage)
        #expect(!store.isUnlocked)
        await store.refresh()
        #expect(!store.isUnlocked)
        #expect(storage.isUnlocked)
        #expect(storage.expirationDate == date)
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
        #expect(storage.expirationDate == nil)
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
