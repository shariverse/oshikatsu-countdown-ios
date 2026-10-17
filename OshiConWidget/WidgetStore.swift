//
//  WidgetStore.swift
//  OshiConWidget
//

import Foundation
import os
import SwiftData

/// ウィジェットで使う、App Group のストアから読んだ予定と推し。
nonisolated struct WidgetData: Sendable {
    let events: [OshiEvent]
    let oshis: [Oshi]

    static let empty = Self(events: [], oshis: [])
}

/// ウィジェットから App Group のストア（アプリと共有）を読む。SwiftData のモデルはメインアクターで扱い、
/// 値の型（`OshiEvent`・`Oshi`）に写してから返す。
enum WidgetStore {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "WidgetStore")
    private static var container: ModelContainer?

    /// 予定と推しを読む。ストアを開けない・読めないときは空（ウィジェットは「予定が見つかりません」などを出す）。
    static func load() -> WidgetData {
        do {
            let container = try container ?? OshiConStore.makeContainer(.appGroup)
            Self.container = container
            // アプリが保存した最新の中身を読むため、毎回新しい context で読む
            let store = OshiConStore(context: ModelContext(container))
            return WidgetData(events: try store.events(), oshis: try store.oshis())
        } catch {
            logger.error("ウィジェットでストアを読めなかった: \(error.localizedDescription)")
            return .empty
        }
    }
}
