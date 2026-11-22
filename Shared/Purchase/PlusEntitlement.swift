//
//  PlusEntitlement.swift
//  OshiCon
//

import Foundation

/// 推し活カウントダウン Plus の商品。productId の正は `docs/app-store/in-app-purchases.json`（一度作ると変えられない）。
nonisolated enum PlusProduct: String, CaseIterable, Sendable {
    /// 月額のサブスクリプション。
    case monthly = "jp.shilokuma.OshiCon.plus.monthly"
    /// 年額のサブスクリプション（1 週間の無料のお試し）。
    case yearly = "jp.shilokuma.OshiCon.plus.yearly"
    /// 買い切り（非消耗型。今後足す Plus の機能も含む）。
    case lifetime = "jp.shilokuma.OshiCon.plus.lifetime"

    /// サブスクリプション（月額・年額）か。
    var isSubscription: Bool {
        switch self {
        case .monthly, .yearly:
            true
        case .lifetime:
            false
        }
    }

    /// サブスクリプションの productId（月額・年額）。
    static var subscriptionIDs: [String] {
        allCases.filter(\.isSubscription).map(\.rawValue)
    }

    /// すべての productId。
    static var allIDs: [String] {
        allCases.map(\.rawValue)
    }
}

/// 購入の記録 1 件（StoreKit の検証済みの取引から写した値）。規則を StoreKit から切り離してテストするための型。
nonisolated struct PlusPurchase: Hashable, Sendable {
    let productID: String
    /// サブスクリプションの期限。買い切りは nil。
    let expirationDate: Date?
    /// 返金・取り消しの日時。あれば使えない。
    let revocationDate: Date?
    /// 請求に失敗したときの猶予期間（Billing Grace Period）の終わり。猶予期間中でなければ nil。
    let gracePeriodExpirationDate: Date?
    /// サブスクリプションが次の期限で自動で更新されるか（解約していないか）。分からないときは true（解約の案内を出すほうに倒す）。
    /// 買い切りでは使わない。
    let willAutoRenew: Bool

    init(
        productID: String,
        expirationDate: Date? = nil,
        revocationDate: Date? = nil,
        gracePeriodExpirationDate: Date? = nil,
        willAutoRenew: Bool = true
    ) {
        self.productID = productID
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.gracePeriodExpirationDate = gracePeriodExpirationDate
        self.willAutoRenew = willAutoRenew
    }
}

/// 「Plus が使えるか」を購入の記録から決める規則。
///
/// - 月額か年額のサブスクリプションが期限の前なら使える。期限を過ぎても猶予期間の終わりの前なら使える
/// - 買い切りがあれば使える
/// - 返金・取り消し（`revocationDate`）があるもの、期限切れのもの、知らない商品は数えない
nonisolated enum PlusEntitlement {
    /// どれか 1 件でも使える購入があれば true。
    static func isUnlocked(purchases: [PlusPurchase], now: Date) -> Bool {
        purchases.contains { grants($0, now: now) }
    }

    /// この購入で Plus が使えるか。
    static func grants(_ purchase: PlusPurchase, now: Date) -> Bool {
        guard purchase.revocationDate == nil, let product = PlusProduct(rawValue: purchase.productID) else {
            return false
        }
        guard product.isSubscription else {
            return true
        }
        let ends = [purchase.expirationDate, purchase.gracePeriodExpirationDate].compactMap(\.self)
        return ends.contains { now < $0 }
    }
}
