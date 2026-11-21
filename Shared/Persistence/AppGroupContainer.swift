//
//  AppGroupContainer.swift
//  OshiCon
//

import Foundation
import os

/// アプリとウィジェットで共有する App Group のコンテナ。SwiftData のストアと推しの写真を置く。
/// Plus が使えるかの判定の結果は、App Group の UserDefaults（`sharedDefaults`）に置く。
nonisolated enum AppGroupContainer {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "AppGroupContainer")

    /// Info.plist の `AppGroupIdentifier`（`Configs/Project.xcconfig` の `APP_GROUP_IDENTIFIER`）。
    static var identifier: String? {
        Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
    }

    /// データを置くディレクトリ（App Group のコンテナの Library/Application Support）。
    /// App Group が使えないとき（Entitlements が付いていないビルドなど）は、アプリだけの Application Support に置く。
    static var dataDirectory: URL {
        if let identifier,
           let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return container.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        }
        logger.error("App Group のコンテナを開けないため、アプリの Application Support を使う")
        return URL.applicationSupportDirectory
    }

    /// SwiftData のストアのファイル。
    static var storeURL: URL {
        dataDirectory.appending(path: "OshiCon.store", directoryHint: .notDirectory)
    }

    /// アプリとウィジェットで共有する UserDefaults（`PrivacyInfo.xcprivacy` の 1C8F.1）。
    /// App Group が使えないときは、アプリだけの UserDefaults を使う。
    static var sharedDefaults: UserDefaults {
        if let identifier, let defaults = UserDefaults(suiteName: identifier) {
            return defaults
        }
        logger.error("App Group の UserDefaults を開けないため、アプリの UserDefaults を使う")
        return .standard
    }
}
