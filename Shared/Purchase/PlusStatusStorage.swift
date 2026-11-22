//
//  PlusStatusStorage.swift
//  OshiCon
//

import Foundation
import SwiftUI

/// 「Plus が使えるか」の判定の結果と、その期限を置く場所。アプリ（`PlusStore`）が書き、Widget Extension が読む（`PlusWidgetStatus`）。
///
/// App Group の UserDefaults（`PrivacyInfo.xcprivacy` の 1C8F.1。アプリと Widget Extension の両方で申告する）に置く。
/// 置くのは判定の結果と期限だけで、取引の中身は置かない。
nonisolated struct PlusStatusStorage {
    static let unlockedKey = "plusUnlocked"
    static let expirationDateKey = "plusExpirationDate"

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

    /// Plus が使えなくなる日時（`PlusEntitlement.expirationDate(purchases:now:)`）。
    /// 買い切り・使えない・書いたことが無いときは nil。
    var expirationDate: Date? {
        get { defaults.object(forKey: Self.expirationDateKey) as? Date }
        nonmutating set {
            if let newValue {
                defaults.set(newValue, forKey: Self.expirationDateKey)
            } else {
                defaults.removeObject(forKey: Self.expirationDateKey)
            }
        }
    }

    /// 判定の結果と期限を書く。どちらかが変わったら true（ウィジェットを描き直す合図）。
    @discardableResult
    func write(isUnlocked unlocked: Bool, expirationDate expiration: Date?) -> Bool {
        let changed = isUnlocked != unlocked || expirationDate != expiration
        if changed {
            isUnlocked = unlocked
            expirationDate = expiration
        }
        return changed
    }
}

extension EnvironmentValues {
    /// Plus が使えるか。画面はここを見て Plus の機能を出し分ける（アプリでは `PlusStore` が入れる。既定は false）。
    @Entry var isPlusUnlocked = false
}
