//
//  PlusWidgetStatus.swift
//  OshiCon
//

import Foundation

/// Widget Extension が「Plus が使えるか」を決める規則。
///
/// - App Group に置いた結果（`PlusStatusStorage`）が使えないなら使えない（買ったらアプリが書いて描き直す）
/// - 使えて期限が無い（買い切り）か、期限の前なら使える
/// - 使えるが期限を過ぎていたら（アプリを開かずに更新・解約・期限切れになったとき）、StoreKit の今の権利で確かめ直す。
///   更新されていれば使え、されていなければ使えない。通信はしない
///
/// App Group には書かない（書くのはアプリの `PlusStore` だけ）。
nonisolated struct PlusWidgetStatus {
    /// App Group の結果だけで決めた答え。
    enum StoredDecision: Equatable {
        case unlocked
        case locked
        /// 期限を過ぎたので StoreKit で確かめ直す。
        case needsVerification
    }

    /// 決めた答え。
    struct Resolution: Equatable, Sendable {
        let isUnlocked: Bool
        /// 使えなくなる日時（タイムラインのエントリを置く）。買い切り・使えないときは nil。
        let expirationDate: Date?
    }

    let storage: PlusStatusStorage
    /// StoreKit の今の権利を読む（テストでは差し替える）。
    let currentPurchases: @Sendable () async -> [PlusPurchase]

    init(
        storage: PlusStatusStorage = .appGroup,
        currentPurchases: @escaping @Sendable () async -> [PlusPurchase] = { await PlusTransactions.currentPurchases() }
    ) {
        self.storage = storage
        self.currentPurchases = currentPurchases
    }

    /// App Group の結果と期限と現在時刻で決める。期限ちょうどで確かめ直す（`PlusEntitlement` と同じく期限の時刻は含まない）。
    static func decision(isUnlocked: Bool, expirationDate: Date?, now: Date) -> StoredDecision {
        guard isUnlocked else {
            return .locked
        }
        guard let expirationDate else {
            return .unlocked
        }
        return now < expirationDate ? .unlocked : .needsVerification
    }

    /// Plus が使えるかと、使えなくなる日時を決める。
    func resolve(now: Date) async -> Resolution {
        let unlocked = storage.isUnlocked
        let expirationDate = storage.expirationDate
        switch Self.decision(isUnlocked: unlocked, expirationDate: expirationDate, now: now) {
        case .unlocked:
            return Resolution(isUnlocked: true, expirationDate: expirationDate)
        case .locked:
            return Resolution(isUnlocked: false, expirationDate: nil)
        case .needsVerification:
            let purchases = await currentPurchases()
            guard PlusEntitlement.isUnlocked(purchases: purchases, now: now) else {
                return Resolution(isUnlocked: false, expirationDate: nil)
            }
            return Resolution(
                isUnlocked: true,
                expirationDate: PlusEntitlement.expirationDate(purchases: purchases, now: now)
            )
        }
    }
}
