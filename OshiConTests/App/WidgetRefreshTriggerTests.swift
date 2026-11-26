//
//  WidgetRefreshTriggerTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftData
import Testing
import UIKit

struct WidgetRefreshTriggerTests {
    @Test("ウィジェットは保存・時刻の大きな変化・タイムゾーンの変更で描き直す")
    func triggers() {
        #expect(WidgetRefreshTrigger.allCases.map(\.notificationName) == [
            ModelContext.didSave,
            UIApplication.significantTimeChangeNotification,
            .NSSystemTimeZoneDidChange
        ])
    }

    /// 推し・予定・写真（推しの写真のファイル名）の保存と削除は、どれも `ModelContext.didSave` を出し、
    /// すべてのウィジェット（カウントダウン・推しカウント・推しの写真）が描き直される。
    @Test("推し・予定・写真の保存と削除は、どれも描き直しのきっかけ（保存）を出す")
    func storeChangesPostSave() async throws {
        let container = try OshiConStore.makeContainer(.inMemory)
        let store = OshiConStore(context: ModelContext(container))
        let now = DomainFixtures.date(2026, 10, 1)

        // 推しを写真つきで登録する
        var oshi = Oshi(name: "ミナト", color: .pink, photoFileName: "\(UUID().uuidString).jpg")
        try await expectSaves(1, in: store.context) {
            try store.save(oshi, now: now)
        }

        // 写真を差し替える（取り込みで新しいファイル名になる）・外す
        try await expectSaves(2, in: store.context) {
            oshi.photoFileName = "\(UUID().uuidString).jpg"
            try store.save(oshi, now: now)
            oshi.photoFileName = nil
            try store.save(oshi, now: now)
        }

        // 予定を登録・更新・ピン留め・削除する
        var event = OshiEvent(
            oshiID: oshi.id,
            kind: .live,
            title: "ライブ",
            day: DomainFixtures.day(2026, 10, 18),
            createdAt: now
        )
        try await expectSaves(4, in: store.context) {
            try store.save(event)
            event.title = "ツアー"
            try store.save(event)
            try store.setPinned(true, eventID: event.id)
            try store.deleteEvent(id: event.id)
        }

        // 推しを削除する（結び付いた予定も消える）
        try await expectSaves(2, in: store.context) {
            try store.save(event)
            try store.deleteOshi(id: oshi.id)
        }
    }

    /// `changes` の間に、`context` が描き直しのきっかけ（保存）をちょうど `count` 回出すことを確かめる。
    private func expectSaves(_ count: Int, in context: ModelContext, _ changes: () throws -> Void) async throws {
        try await confirmation("保存の通知", expectedCount: count) { saved in
            let observer = NotificationCenter.default.addObserver(
                forName: WidgetRefreshTrigger.save.notificationName,
                object: context,
                queue: nil
            ) { _ in
                saved()
            }
            defer {
                NotificationCenter.default.removeObserver(observer)
            }
            try changes()
        }
    }
}
