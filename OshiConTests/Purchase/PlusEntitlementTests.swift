//
//  PlusEntitlementTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct PlusEntitlementTests {
    private let now = DomainFixtures.date(2026, 11, 21, 12, 0)
    private var past: Date { now.addingTimeInterval(-60) }
    private var future: Date { now.addingTimeInterval(60) }

    private func monthly(expires: Date, revoked: Date? = nil, graceEnds: Date? = nil) -> PlusPurchase {
        PlusPurchase(
            productID: PlusProduct.monthly.rawValue,
            expirationDate: expires,
            revocationDate: revoked,
            gracePeriodExpirationDate: graceEnds
        )
    }

    private var lifetime: PlusPurchase {
        PlusPurchase(productID: PlusProduct.lifetime.rawValue)
    }

    @Test("productId は in-app-purchases.json と同じ。サブスクリプションは月額と年額")
    func productIDs() {
        #expect(PlusProduct.allIDs == [
            "jp.shilokuma.OshiCon.plus.monthly",
            "jp.shilokuma.OshiCon.plus.yearly",
            "jp.shilokuma.OshiCon.plus.lifetime"
        ])
        #expect(PlusProduct.subscriptionIDs == ["jp.shilokuma.OshiCon.plus.monthly", "jp.shilokuma.OshiCon.plus.yearly"])
    }

    @Test("月額・年額のサブスクリプションは期限の前なら使える")
    func activeSubscription() {
        for product in [PlusProduct.monthly, .yearly] {
            let purchase = PlusPurchase(productID: product.rawValue, expirationDate: future)
            #expect(PlusEntitlement.isUnlocked(purchases: [purchase], now: now), "\(product)")
        }
    }

    @Test("期限を過ぎたサブスクリプションは使えない。期限ちょうどで使えなくなる")
    func expiredSubscription() {
        #expect(!PlusEntitlement.isUnlocked(purchases: [monthly(expires: past)], now: now))
        #expect(!PlusEntitlement.isUnlocked(purchases: [monthly(expires: now)], now: now))
    }

    @Test("期限を過ぎても猶予期間の間は使え、猶予期間を過ぎたら使えない")
    func gracePeriod() {
        #expect(PlusEntitlement.isUnlocked(purchases: [monthly(expires: past, graceEnds: future)], now: now))
        #expect(!PlusEntitlement.isUnlocked(purchases: [monthly(expires: past, graceEnds: past)], now: now))
    }

    @Test("返金・取り消しされたものは、期限の前でも猶予期間中でも買い切りでも使えない")
    func revoked() {
        #expect(!PlusEntitlement.isUnlocked(purchases: [monthly(expires: future, revoked: past)], now: now))
        #expect(!PlusEntitlement.isUnlocked(purchases: [monthly(expires: past, revoked: past, graceEnds: future)], now: now))
        let revokedLifetime = PlusPurchase(productID: PlusProduct.lifetime.rawValue, revocationDate: past)
        #expect(!PlusEntitlement.isUnlocked(purchases: [revokedLifetime], now: now))
    }

    @Test("買い切りは期限が無く、使える")
    func lifetimePurchase() {
        #expect(PlusEntitlement.isUnlocked(purchases: [lifetime], now: now))
    }

    @Test("サブスクリプションと買い切りの両方があれば使え、サブスクリプションが切れても買い切りで使える")
    func both() {
        #expect(PlusEntitlement.isUnlocked(purchases: [monthly(expires: future), lifetime], now: now))
        #expect(PlusEntitlement.isUnlocked(purchases: [monthly(expires: past), lifetime], now: now))
    }

    @Test("返金された買い切りがあっても、有効なサブスクリプションで使える")
    func revokedLifetimeWithSubscription() {
        let revokedLifetime = PlusPurchase(productID: PlusProduct.lifetime.rawValue, revocationDate: past)
        #expect(PlusEntitlement.isUnlocked(purchases: [revokedLifetime, monthly(expires: future)], now: now))
    }

    @Test("未購入と、知らない商品だけでは使えない")
    func notPurchased() {
        #expect(!PlusEntitlement.isUnlocked(purchases: [], now: now))
        #expect(!PlusEntitlement.isUnlocked(purchases: [PlusPurchase(productID: "jp.shilokuma.OshiCon.other")], now: now))
    }

    @Test("期限の無いサブスクリプションの記録は使えないものとして扱う")
    func subscriptionWithoutExpiration() {
        #expect(!PlusEntitlement.isUnlocked(purchases: [PlusPurchase(productID: PlusProduct.yearly.rawValue)], now: now))
    }

    @Test("使えるサブスクリプションの期限は、サブスクリプションの期限")
    func expirationOfSubscription() {
        #expect(PlusEntitlement.expirationDate(purchases: [monthly(expires: future)], now: now) == future)
    }

    @Test("猶予期間の終わりが期限より遅ければ猶予期間の終わり、早ければ期限")
    func expirationWithGracePeriod() {
        let later = now.addingTimeInterval(3_600)
        #expect(PlusEntitlement.expirationDate(purchases: [monthly(expires: past, graceEnds: later)], now: now) == later)
        #expect(PlusEntitlement.expirationDate(purchases: [monthly(expires: later, graceEnds: future)], now: now) == later)
    }

    @Test("サブスクリプションが複数あれば、使えるもののうちいちばん遅い期限")
    func expirationOfMultipleSubscriptions() {
        let later = now.addingTimeInterval(3_600)
        let yearly = PlusPurchase(productID: PlusProduct.yearly.rawValue, expirationDate: later)
        #expect(PlusEntitlement.expirationDate(purchases: [monthly(expires: future), yearly], now: now) == later)
        let revokedYearly = PlusPurchase(productID: PlusProduct.yearly.rawValue, expirationDate: later, revocationDate: past)
        #expect(PlusEntitlement.expirationDate(purchases: [monthly(expires: future), revokedYearly], now: now) == future)
    }

    @Test("買い切りがあれば、サブスクリプションがあっても期限は無い")
    func expirationOfLifetime() {
        #expect(PlusEntitlement.expirationDate(purchases: [lifetime], now: now) == nil)
        #expect(PlusEntitlement.expirationDate(purchases: [monthly(expires: future), lifetime], now: now) == nil)
    }

    @Test("返金された買い切りは数えず、サブスクリプションの期限になる")
    func expirationWithRevokedLifetime() {
        let revokedLifetime = PlusPurchase(productID: PlusProduct.lifetime.rawValue, revocationDate: past)
        #expect(PlusEntitlement.expirationDate(purchases: [revokedLifetime, monthly(expires: future)], now: now) == future)
    }

    @Test("使える購入が無ければ期限も無い（期限ちょうど・期限切れ・猶予期間切れ・未購入・返金）")
    func expirationWhenLocked() {
        #expect(PlusEntitlement.expirationDate(purchases: [], now: now) == nil)
        #expect(PlusEntitlement.expirationDate(purchases: [monthly(expires: now)], now: now) == nil)
        #expect(PlusEntitlement.expirationDate(purchases: [monthly(expires: past, graceEnds: past)], now: now) == nil)
        #expect(PlusEntitlement.expirationDate(purchases: [monthly(expires: future, revoked: past)], now: now) == nil)
        #expect(PlusEntitlement.expirationDate(purchases: [PlusPurchase(productID: "jp.shilokuma.OshiCon.other")], now: now) == nil)
    }
}
