//
//  OshiConStore.swift
//  OshiCon
//

import Foundation
import os
import SwiftData

/// 推しと予定の保存・削除。
///
/// 保存・削除に失敗したら投げ、途中の変更は取り消す（呼び出し側は「保存できませんでした」を出し、入力を残してもう一度押せるようにする）。
/// 取り消しは渡した `ModelContext` の保存していない変更をすべて捨てるので、その context への書き込みはすべてこのストアを通す。
final class OshiConStore {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "OshiConStore")

    /// ストアの置き場所。
    enum Location {
        /// アプリとウィジェットで共有する App Group のコンテナ。
        case appGroup
        /// メモリ上（テスト・Preview・UI テスト）。
        case inMemory
        /// 指定したファイル（テスト）。
        case file(URL)
    }

    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// ストアを開く。iCloud には同期しない（端末の外に送らない）。`allowsSave` はテストで保存を失敗させるために使う。
    static func makeContainer(_ location: Location = .appGroup, allowsSave: Bool = true) throws -> ModelContainer {
        let schema = Schema(versionedSchema: OshiConSchemaV1.self)
        let configuration: ModelConfiguration
        switch location {
        case .inMemory:
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, allowsSave: allowsSave, cloudKitDatabase: .none)
        case .appGroup:
            try FileManager.default.createDirectory(at: AppGroupContainer.dataDirectory, withIntermediateDirectories: true)
            configuration = ModelConfiguration(
                schema: schema,
                url: AppGroupContainer.storeURL,
                allowsSave: allowsSave,
                cloudKitDatabase: .none
            )
        case let .file(url):
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            configuration = ModelConfiguration(schema: schema, url: url, allowsSave: allowsSave, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, migrationPlan: OshiConMigrationPlan.self, configurations: configuration)
    }

    // MARK: - 読む

    /// 推しを登録した順に。
    func oshis() throws -> [Oshi] {
        let descriptor = FetchDescriptor<StoredOshi>(sortBy: [SortDescriptor(\.createdAt), SortDescriptor(\.name)])
        return try context.fetch(descriptor).map(Self.oshi(from:))
    }

    /// すべての予定。並びは `EventSchedule` で決める。
    func events() throws -> [OshiEvent] {
        try context.fetch(FetchDescriptor<StoredEvent>()).compactMap(Self.event(from:))
    }

    func event(id: OshiEvent.ID) throws -> OshiEvent? {
        try storedEvent(id: id).flatMap(Self.event(from:))
    }

    /// 推しに結び付いた予定の件数（推しの削除の確認に出す）。
    func eventCount(oshiID: Oshi.ID) throws -> Int {
        try storedOshi(id: oshiID)?.events.count ?? 0
    }

    // MARK: - 推しの保存・削除

    /// 推しを追加するか、同じ `id` の推しを更新する。`now` は追加するときの登録した時刻。
    func save(_ oshi: Oshi, now: Date) throws {
        try performChanges {
            if let stored = try storedOshi(id: oshi.id) {
                stored.name = oshi.name
                stored.colorRawValue = oshi.color.rawValue
                stored.photoFileName = oshi.photoFileName
            } else {
                context.insert(
                    StoredOshi(
                        id: oshi.id,
                        name: oshi.name,
                        colorRawValue: oshi.color.rawValue,
                        photoFileName: oshi.photoFileName,
                        createdAt: now
                    )
                )
            }
        }
    }

    /// 推しと、結び付いた予定を消す。消した推し（写真を消すため）を返す。見つからなければ nil。
    @discardableResult
    func deleteOshi(id: Oshi.ID) throws -> Oshi? {
        guard let stored = try storedOshi(id: id) else {
            return nil
        }
        let deleted = Self.oshi(from: stored)
        try performChanges {
            // 関係の削除規則（cascade）に任せず明示的に消し、保存の前に消える予定を確定させる
            for event in stored.events {
                context.delete(event)
            }
            context.delete(stored)
        }
        return deleted
    }

    // MARK: - 予定の保存・削除

    /// 予定を追加するか、同じ `id` の予定を更新する。ピン留めした予定を保存すると、ほかの予定のピン留めは外れる。
    /// 結び付く推しが見つからなければ「推しなし」として保存する。
    func save(_ event: OshiEvent) throws {
        try performChanges {
            let oshi = try event.oshiID.flatMap { try storedOshi(id: $0) }
            let stored: StoredEvent
            if let existing = try storedEvent(id: event.id) {
                stored = existing
            } else {
                stored = StoredEvent(
                    id: event.id,
                    oshi: nil,
                    kindRawValue: event.kind.rawValue,
                    title: event.title,
                    year: event.day.year,
                    month: event.day.month,
                    day: event.day.day,
                    startMinutes: nil,
                    venue: event.venue,
                    repeatsYearly: event.repeatsYearly,
                    isPinned: false,
                    createdAt: event.createdAt
                )
                context.insert(stored)
            }
            stored.oshi = oshi
            stored.kindRawValue = event.kind.rawValue
            stored.title = event.title
            stored.year = event.day.year
            stored.month = event.day.month
            stored.day = event.day.day
            stored.startMinutes = event.startTime?.minutesSinceMidnight
            stored.venue = event.venue
            stored.repeatsYearly = event.repeatsYearly
            if event.isPinned {
                try unpinAll(except: event.id)
            }
            stored.isPinned = event.isPinned
        }
    }

    func deleteEvent(id: OshiEvent.ID) throws {
        guard let stored = try storedEvent(id: id) else {
            return
        }
        try performChanges {
            context.delete(stored)
        }
    }

    /// ピン留めを切り替える。ピン留めすると、ほかの予定のピン留めは外れる。
    func setPinned(_ isPinned: Bool, eventID: OshiEvent.ID) throws {
        guard let stored = try storedEvent(id: eventID) else {
            return
        }
        try performChanges {
            if isPinned {
                try unpinAll(except: eventID)
            }
            stored.isPinned = isPinned
        }
    }

    // MARK: - 写し

    static func oshi(from stored: StoredOshi) -> Oshi {
        Oshi(
            id: stored.id,
            name: stored.name,
            color: OshiColor(rawValue: stored.colorRawValue) ?? .defaultColor,
            photoFileName: stored.photoFileName
        )
    }

    /// 保存した値が壊れていて写せない予定は nil（読み飛ばす）。
    static func event(from stored: StoredEvent) -> OshiEvent? {
        guard (1...9_999).contains(stored.year), (1...12).contains(stored.month), stored.day >= 1 else {
            logger.error("日付が範囲外の予定を読み飛ばす: \(stored.year)-\(stored.month)-\(stored.day)")
            return nil
        }
        let startTime: TimeOfDay?
        if let minutes = stored.startMinutes {
            guard (0..<24 * 60).contains(minutes) else {
                logger.error("時刻が範囲外の予定を読み飛ばす: \(minutes)")
                return nil
            }
            startTime = TimeOfDay(hour: minutes / 60, minute: minutes % 60)
        } else {
            startTime = nil
        }
        return OshiEvent(
            id: stored.id,
            oshiID: stored.oshi?.id,
            kind: EventKind(rawValue: stored.kindRawValue) ?? .other,
            title: stored.title,
            day: CalendarDay(year: stored.year, month: stored.month, day: stored.day),
            startTime: startTime,
            venue: stored.venue,
            repeatsYearly: stored.repeatsYearly,
            isPinned: stored.isPinned,
            createdAt: stored.createdAt
        )
    }

    // MARK: - 内部

    private func storedOshi(id: Oshi.ID) throws -> StoredOshi? {
        var descriptor = FetchDescriptor<StoredOshi>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func storedEvent(id: OshiEvent.ID) throws -> StoredEvent? {
        var descriptor = FetchDescriptor<StoredEvent>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func unpinAll(except id: OshiEvent.ID) throws {
        let pinned = try context.fetch(FetchDescriptor<StoredEvent>(predicate: #Predicate { $0.isPinned && $0.id != id }))
        for event in pinned {
            event.isPinned = false
        }
    }

    /// 変更を保存する。失敗したら変更を取り消して投げる。
    private func performChanges(_ changes: () throws -> Void) throws {
        do {
            try changes()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
