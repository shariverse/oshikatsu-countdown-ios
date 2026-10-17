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
}

/// ウィジェットから App Group のストア（アプリと共有）を読む。SwiftData のモデルはメインアクターで扱い、
/// 値の型（`OshiEvent`・`Oshi`）に写してから返す。
///
/// ストアのスキーマを変えて移行の段を足すときは、アプリとウィジェットが同時に移行を走らせないよう、
/// ウィジェットでは移行せずに読めないものとして扱う（アプリを開いて移行してから読む）方針にする。
enum WidgetStore {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "WidgetStore")
    private static var container: ModelContainer?

    /// 予定と推しを読む。読めないときは nil（「予定が見つかりません」と区別して、しばらくしてから読み直す）。
    static func load() -> WidgetData? {
        // App Group が使えないと、ウィジェットだけの場所に空のストアを作ってしまうので読まない
        guard let identifier = AppGroupContainer.identifier,
              FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil else {
            logger.error("ウィジェットで App Group のコンテナを開けない")
            return nil
        }
        do {
            let container = try container ?? OshiConStore.makeContainer(.appGroup)
            Self.container = container
            // アプリが保存した最新の中身を読むため、毎回新しい context で読む
            let store = OshiConStore(context: ModelContext(container))
            return WidgetData(events: try store.events(), oshis: try store.oshis())
        } catch {
            logger.error("ウィジェットでストアを読めなかった: \(error.localizedDescription)")
            return nil
        }
    }
}
