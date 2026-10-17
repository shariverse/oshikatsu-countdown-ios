//
//  OshiConSchema.swift
//  OshiCon
//

import Foundation
import SwiftData

/// 保存する推し。画面と規則は `Oshi` に写して使う。
typealias StoredOshi = OshiConSchemaV1.StoredOshi
/// 保存する予定。画面と規則は `OshiEvent` に写して使う。
typealias StoredEvent = OshiConSchemaV1.StoredEvent

/// SwiftData のスキーマの 1 版目。
///
/// 最初の TestFlight の配信の後にモデルの形を変えるときは、この版を残したまま `OshiConSchemaV2` を足し、
/// `OshiConMigrationPlan` に移行の段を足す（形を変えた版を上書きすると、配信済みのストアを開けなくなる）。
enum OshiConSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [StoredOshi.self, StoredEvent.self]
    }

    @Model
    final class StoredOshi {
        @Attribute(.unique) var id: UUID
        var name: String
        /// `OshiColor` の rawValue。
        var colorRawValue: String
        /// App Group のコンテナに取り込んだ写真のファイル名。
        var photoFileName: String?
        /// 登録した時刻。推しの一覧の並び（登録した順）に使う。
        var createdAt: Date
        /// 推しを削除すると、結び付いた予定も消す。
        @Relationship(deleteRule: .cascade, inverse: \StoredEvent.oshi)
        var events: [StoredEvent] = []

        init(id: UUID, name: String, colorRawValue: String, photoFileName: String?, createdAt: Date) {
            self.id = id
            self.name = name
            self.colorRawValue = colorRawValue
            self.photoFileName = photoFileName
            self.createdAt = createdAt
        }
    }

    @Model
    final class StoredEvent {
        @Attribute(.unique) var id: UUID
        var oshi: StoredOshi?
        /// `EventKind` の rawValue。
        var kindRawValue: String
        var title: String
        /// 開催日（毎年くり返す予定は最初の回）。書いた日付のまま、年・月・日で持つ。
        var year: Int
        var month: Int
        var day: Int
        /// 開始の時刻（0:00 からの分）。決まっていなければ nil。
        var startMinutes: Int?
        var venue: String
        var repeatsYearly: Bool
        var isPinned: Bool
        var createdAt: Date

        init(
            id: UUID,
            oshi: StoredOshi?,
            kindRawValue: String,
            title: String,
            year: Int,
            month: Int,
            day: Int,
            startMinutes: Int?,
            venue: String,
            repeatsYearly: Bool,
            isPinned: Bool,
            createdAt: Date
        ) {
            self.id = id
            self.oshi = oshi
            self.kindRawValue = kindRawValue
            self.title = title
            self.year = year
            self.month = month
            self.day = day
            self.startMinutes = startMinutes
            self.venue = venue
            self.repeatsYearly = repeatsYearly
            self.isPinned = isPinned
            self.createdAt = createdAt
        }
    }
}

/// スキーマの移行の計画。版を足したら `schemas` と `stages` に足す。
enum OshiConMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [OshiConSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
