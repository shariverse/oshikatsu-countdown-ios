//
//  PlusLifetimeGuidance.swift
//  OshiCon
//

import Foundation

/// サブスクリプション中に買い切りを買う人への案内を出すかの規則。
///
/// 買い切りを買ってもサブスクリプションは自動で止まらない（請求が続く）ので、2 回伝える。
/// - 購入前: 自動で更新されるサブスクリプションがある間は、買い切りのそばに注記を出す
/// - 購入後: 自動で更新されるサブスクリプションがあるまま買い切りの購入が終わったら、案内を出してサブスクリプションの管理を開けるようにする
///
/// 解約済み（期限まで使えるが更新されない）・期限切れ・返金されたサブスクリプションは、請求が続かないので数えない。
nonisolated enum PlusLifetimeGuidance {
    /// 自動で更新されるサブスクリプション（月額・年額）が、今使える状態であるか。猶予期間中も含む。
    /// true の間は、買い切りのそばに注記を出す。
    static func hasRenewingSubscription(purchases: [PlusPurchase], now: Date) -> Bool {
        purchases.contains { purchase in
            guard PlusProduct(rawValue: purchase.productID)?.isSubscription == true, purchase.willAutoRenew else {
                return false
            }
            return PlusEntitlement.grants(purchase, now: now)
        }
    }

    /// 購入が終わったあとに案内を出すか。検証済みの買い切りの購入で、自動で更新されるサブスクリプションがあるときだけ。
    /// - Parameters:
    ///   - productID: 購入が終わった商品
    ///   - isVerified: 取引を検証できたか（検証できない取引は数えないので、案内も出さない）
    ///   - hasRenewingSubscription: 購入の後の、自動で更新されるサブスクリプションがあるか
    static func showsGuideAfterPurchase(productID: String, isVerified: Bool, hasRenewingSubscription: Bool) -> Bool {
        isVerified && productID == PlusProduct.lifetime.rawValue && hasRenewingSubscription
    }
}
