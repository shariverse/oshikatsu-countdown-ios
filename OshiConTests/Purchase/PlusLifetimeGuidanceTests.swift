//
//  PlusLifetimeGuidanceTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct PlusLifetimeGuidanceTests {
    private let now = DomainFixtures.date(2026, 11, 21, 12, 0)
    private var past: Date { now.addingTimeInterval(-60) }
    private var future: Date { now.addingTimeInterval(60) }

    private func subscription(
        _ product: PlusProduct = .monthly,
        expires: Date,
        revoked: Date? = nil,
        graceEnds: Date? = nil,
        renews: Bool = true
    ) -> PlusPurchase {
        PlusPurchase(
            productID: product.rawValue,
            expirationDate: expires,
            revocationDate: revoked,
            gracePeriodExpirationDate: graceEnds,
            willAutoRenew: renews
        )
    }

    private var lifetime: PlusPurchase {
        PlusPurchase(productID: PlusProduct.lifetime.rawValue)
    }

    private func renewing(_ purchases: [PlusPurchase]) -> Bool {
        PlusLifetimeGuidance.hasRenewingSubscription(purchases: purchases, now: now)
    }

    @Test("自動で更新される月額・年額のサブスクリプションが期限の前なら、注記を出す")
    func activeRenewingSubscription() {
        for product in [PlusProduct.monthly, .yearly] {
            #expect(renewing([subscription(product, expires: future)]), "\(product)")
        }
    }

    @Test("猶予期間中でも、自動で更新されるなら注記を出す")
    func gracePeriod() {
        #expect(renewing([subscription(expires: past, graceEnds: future)]))
        #expect(!renewing([subscription(expires: past, graceEnds: past)]))
    }

    @Test("解約済み（期限までは使えるが更新されない）のサブスクリプションでは注記を出さない")
    func cancelledSubscription() {
        #expect(!renewing([subscription(expires: future, renews: false)]))
    }

    @Test("期限切れ・返金されたサブスクリプションでは注記を出さない")
    func expiredOrRevoked() {
        #expect(!renewing([subscription(expires: past)]))
        #expect(!renewing([subscription(expires: now)]))
        #expect(!renewing([subscription(expires: future, revoked: past)]))
    }

    @Test("未購入・買い切りだけ・知らない商品では注記を出さない")
    func noSubscription() {
        #expect(!renewing([]))
        #expect(!renewing([lifetime]))
        let other = PlusPurchase(productID: "jp.shilokuma.OshiCon.other", expirationDate: future)
        #expect(!renewing([other]))
    }

    @Test("買い切りとサブスクリプションの両方があっても、サブスクリプションが更新されるなら注記を出す")
    func both() {
        #expect(renewing([lifetime, subscription(.yearly, expires: future)]))
    }

    @Test("更新の情報が読めない記録は、更新されるものとして扱う（案内を出すほうに倒す）")
    func unknownRenewal() {
        let purchase = PlusPurchase(productID: PlusProduct.monthly.rawValue, expirationDate: future)
        #expect(renewing([purchase]))
    }

    @Test("購入後の案内は、検証済みの買い切りで、自動で更新されるサブスクリプションがあるときだけ出す")
    func guideAfterPurchase() {
        func shows(_ product: PlusProduct, verified: Bool = true, renewing: Bool = true) -> Bool {
            PlusLifetimeGuidance.showsGuideAfterPurchase(
                productID: product.rawValue,
                isVerified: verified,
                hasRenewingSubscription: renewing
            )
        }
        #expect(shows(.lifetime))
        #expect(!shows(.lifetime, renewing: false))
        #expect(!shows(.lifetime, verified: false))
        #expect(!shows(.monthly))
        #expect(!shows(.yearly))
    }

    @Test("メモリ上のストアでは StoreKit に触れず、Preview 用にサブスクリプション中の状態にできる")
    @MainActor
    func inactiveStore() {
        let subscribed = PlusStore(isActive: false, unlocksWhenInactive: false, subscribesWhenInactive: true)
        #expect(subscribed.hasRenewingSubscription)
        #expect(subscribed.isUnlocked)
        let locked = PlusStore(isActive: false, unlocksWhenInactive: false)
        #expect(!locked.hasRenewingSubscription)
        #expect(!locked.isUnlocked)
    }
}
