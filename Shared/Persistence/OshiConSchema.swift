//
//  OshiConSchema.swift
//  OshiCon
//

import Foundation
import SwiftData

/// 保存する推し。画面と規則は `Oshi` に写して使う。
typealias StoredOshi = OshiConSchemaV2.StoredOshi
/// 保存する予定。画面と規則は `OshiEvent` に写して使う。
typealias StoredEvent = OshiConSchemaV2.StoredEvent

/// SwiftData のスキーマの 1 版目（1.2.0 まで）。推しは登録した順に並ぶ。
///
/// 配信済みのストアを開くために残す。形を変えない（変えると配信済みのストアを開けなくなる）。
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

/// SwiftData のスキーマの 2 版目。推しに並び順（`sortOrder`）を足した（推しの並べ替え。#208）。
///
/// モデルの形を変えるときは、この版を残したまま `OshiConSchemaV3` を足し、`OshiConMigrationPlan` に移行の段を足す。
enum OshiConSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
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
        /// 登録した時刻。並び順が同じ推し（V1 から移行した推し）の並びに使う。
        var createdAt: Date
        /// 推しの並び順（小さいほど上。いちばん上が 1 位の推し）。V1 から移行した推しは 0 で、登録した順に並ぶ。
        var sortOrder: Int = 0
        /// 推しを削除すると、結び付いた予定も消す。
        @Relationship(deleteRule: .cascade, inverse: \StoredEvent.oshi)
        var events: [StoredEvent] = []

        init(id: UUID, name: String, colorRawValue: String, photoFileName: String?, createdAt: Date, sortOrder: Int) {
            self.id = id
            self.name = name
            self.colorRawValue = colorRawValue
            self.photoFileName = photoFileName
            self.createdAt = createdAt
            self.sortOrder = sortOrder
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
        [OshiConSchemaV1.self, OshiConSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            // V1 → V2: 推しに並び順を足す。足した項目は既定値（0）で埋まり、並びは登録した順のまま（軽量の移行）
            .lightweight(fromVersion: OshiConSchemaV1.self, toVersion: OshiConSchemaV2.self)
        ]
    }
}
