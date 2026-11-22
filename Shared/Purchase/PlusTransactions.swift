//
//  PlusTransactions.swift
//  OshiCon
//

import Foundation
import StoreKit

/// StoreKit 2 の今の権利を購入の記録（`PlusPurchase`）に写す。アプリ（`PlusStore`）と Widget Extension（`PlusWidgetStatus`）の両方で使う。
///
/// 検証済みの取引だけを数える。通信はせず、確かめるのは StoreKit が端末の中でする検証だけ。
nonisolated enum PlusTransactions {
    /// 今の権利（Plus の商品の、検証済みの取引）を購入の記録に写す。
    static func currentPurchases() async -> [PlusPurchase] {
        var purchases: [PlusPurchase] = []
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case let .verified(transaction) = result, PlusProduct(rawValue: transaction.productID) != nil else {
                continue
            }
            purchases.append(await purchase(from: transaction))
        }
        return purchases
    }

    private static func purchase(from transaction: StoreKit.Transaction) async -> PlusPurchase {
        var gracePeriodExpirationDate: Date?
        // 更新の情報が読めないときは、解約の案内を出すほうに倒す
        var willAutoRenew = true
        // 猶予期間中は取引の期限を過ぎているので、更新の情報から猶予期間の終わりを読む
        if transaction.productType == .autoRenewable,
           let status = await transaction.subscriptionStatus,
           case let .verified(renewalInfo) = status.renewalInfo {
            gracePeriodExpirationDate = renewalInfo.gracePeriodExpirationDate
            willAutoRenew = renewalInfo.willAutoRenew
        }
        return PlusPurchase(
            productID: transaction.productID,
            expirationDate: transaction.expirationDate,
            revocationDate: transaction.revocationDate,
            gracePeriodExpirationDate: gracePeriodExpirationDate,
            willAutoRenew: willAutoRenew
        )
    }
}
