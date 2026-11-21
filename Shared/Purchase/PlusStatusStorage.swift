//
//  PlusStatusStorage.swift
//  OshiCon
//

import Foundation
import SwiftUI

/// 「Plus が使えるか」の判定の結果を置く場所。アプリ（`PlusStore`）が書き、Widget Extension が読む。
///
/// App Group の UserDefaults（`PrivacyInfo.xcprivacy` の 1C8F.1。アプリと Widget Extension の両方で申告する）に置く。
/// 置くのは判定の結果だけで、取引の中身は置かない。
nonisolated struct PlusStatusStorage {
    static let unlockedKey = "plusUnlocked"

    let defaults: UserDefaults

    /// App Group の UserDefaults（アプリと Widget Extension で共有する）。
    static var appGroup: Self {
        Self(defaults: AppGroupContainer.sharedDefaults)
    }

    /// Plus が使えるか。書いたことが無ければ false。
    var isUnlocked: Bool {
        get { defaults.bool(forKey: Self.unlockedKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.unlockedKey) }
    }
}

extension EnvironmentValues {
    /// Plus が使えるか。画面はここを見て Plus の機能を出し分ける（アプリでは `PlusStore` が入れる。既定は false）。
    @Entry var isPlusUnlocked = false
}
