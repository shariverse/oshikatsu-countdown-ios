//
//  PlusWidgetStatusTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct PlusWidgetStatusTests {
    private let now = DomainFixtures.date(2026, 11, 21, 12, 0)
    private var past: Date { now.addingTimeInterval(-60) }
    private var future: Date { now.addingTimeInterval(60) }

    /// テストごとの UserDefaults（App Group や端末の設定を書き換えない）。
    private static func makeStorage(isUnlocked: Bool, expirationDate: Date?) throws -> PlusStatusStorage {
        let suiteName = "PlusWidgetStatusTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let storage = PlusStatusStorage(defaults: defaults)
        storage.write(isUnlocked: isUnlocked, expirationDate: expirationDate)
        return storage
    }

    /// StoreKit で確かめ直さないはずのときの差し替え。呼ばれたら失敗にする。
    private static let mustNotVerify: @Sendable () async -> [PlusPurchase] = {
        Issue.record("StoreKit で確かめ直した")
        return []
    }

    @Test("使えない結果なら、期限があっても使えない")
    func lockedDecision() {
        #expect(PlusWidgetStatus.decision(isUnlocked: false, expirationDate: nil, now: now) == .locked)
        #expect(PlusWidgetStatus.decision(isUnlocked: false, expirationDate: future, now: now) == .locked)
        #expect(PlusWidgetStatus.decision(isUnlocked: false, expirationDate: past, now: now) == .locked)
    }

    @Test("使える結果で期限が無ければ（買い切り）使える")
    func lifetimeDecision() {
        #expect(PlusWidgetStatus.decision(isUnlocked: true, expirationDate: nil, now: now) == .unlocked)
    }

    @Test("使える結果は期限の前なら使え、期限ちょうどと過ぎたら確かめ直す")
    func expirationBoundary() {
        #expect(PlusWidgetStatus.decision(isUnlocked: true, expirationDate: future, now: now) == .unlocked)
        #expect(PlusWidgetStatus.decision(isUnlocked: true, expirationDate: now.addingTimeInterval(1), now: now) == .unlocked)
        #expect(PlusWidgetStatus.decision(isUnlocked: true, expirationDate: now, now: now) == .needsVerification)
        #expect(PlusWidgetStatus.decision(isUnlocked: true, expirationDate: past, now: now) == .needsVerification)
    }

    @Test("期限の前は StoreKit に触れず、保存した期限のまま使える")
    func beforeExpiration() async throws {
        let storage = try Self.makeStorage(isUnlocked: true, expirationDate: future)
        let status = PlusWidgetStatus(storage: storage, currentPurchases: Self.mustNotVerify)
        let resolution = await status.resolve(now: now)
        #expect(resolution == PlusWidgetStatus.Resolution(isUnlocked: true, expirationDate: future))
    }

    @Test("買い切りは StoreKit に触れず、期限の無いまま使える")
    func lifetime() async throws {
        let storage = try Self.makeStorage(isUnlocked: true, expirationDate: nil)
        let status = PlusWidgetStatus(storage: storage, currentPurchases: Self.mustNotVerify)
        let resolution = await status.resolve(now: now)
        #expect(resolution == PlusWidgetStatus.Resolution(isUnlocked: true, expirationDate: nil))
    }

    @Test("使えない結果と、書いたことが無いときは StoreKit に触れず使えない")
    func locked() async throws {
        let storage = try Self.makeStorage(isUnlocked: false, expirationDate: nil)
        let status = PlusWidgetStatus(storage: storage, currentPurchases: Self.mustNotVerify)
        #expect(await status.resolve(now: now) == PlusWidgetStatus.Resolution(isUnlocked: false, expirationDate: nil))
    }

    @Test("期限を過ぎて、StoreKit で更新されていれば、新しい期限で使える")
    func renewedAfterExpiration() async throws {
        let renewed = now.addingTimeInterval(30 * 24 * 3_600)
        let storage = try Self.makeStorage(isUnlocked: true, expirationDate: past)
        let status = PlusWidgetStatus(storage: storage) {
            [PlusPurchase(productID: PlusProduct.monthly.rawValue, expirationDate: renewed)]
        }
        #expect(await status.resolve(now: now) == PlusWidgetStatus.Resolution(isUnlocked: true, expirationDate: renewed))
    }

    @Test("期限ちょうどで確かめ直し、猶予期間に入っていれば猶予期間の終わりまで使える")
    func gracePeriodAtExpiration() async throws {
        let graceEnds = now.addingTimeInterval(3_600)
        let storage = try Self.makeStorage(isUnlocked: true, expirationDate: now)
        let status = PlusWidgetStatus(storage: storage) {
            [
                PlusPurchase(
                    productID: PlusProduct.yearly.rawValue,
                    expirationDate: graceEnds - 7_200,
                    gracePeriodExpirationDate: graceEnds
                )
            ]
        }
        #expect(await status.resolve(now: now) == PlusWidgetStatus.Resolution(isUnlocked: true, expirationDate: graceEnds))
    }

    @Test("期限を過ぎて、StoreKit で買い切りが見つかれば、期限の無いまま使える")
    func lifetimeFoundAfterExpiration() async throws {
        let storage = try Self.makeStorage(isUnlocked: true, expirationDate: past)
        let status = PlusWidgetStatus(storage: storage) {
            [PlusPurchase(productID: PlusProduct.lifetime.rawValue)]
        }
        #expect(await status.resolve(now: now) == PlusWidgetStatus.Resolution(isUnlocked: true, expirationDate: nil))
    }

    @Test("期限を過ぎて、StoreKit で更新されていなければ（期限切れ・返金・権利なし）使えない")
    func expiredAfterVerification() async throws {
        let cases: [[PlusPurchase]] = [
            [],
            [PlusPurchase(productID: PlusProduct.monthly.rawValue, expirationDate: past)],
            [PlusPurchase(productID: PlusProduct.monthly.rawValue, expirationDate: future, revocationDate: past)]
        ]
        for purchases in cases {
            let storage = try Self.makeStorage(isUnlocked: true, expirationDate: past)
            let status = PlusWidgetStatus(storage: storage) { purchases }
            #expect(await status.resolve(now: now) == PlusWidgetStatus.Resolution(isUnlocked: false, expirationDate: nil))
        }
    }

    @Test("ウィジェットは確かめ直した結果を App Group に書かない（書くのはアプリだけ）")
    func doesNotWriteStorage() async throws {
        let storage = try Self.makeStorage(isUnlocked: true, expirationDate: past)
        let status = PlusWidgetStatus(storage: storage) { [] }
        _ = await status.resolve(now: now)
        #expect(storage.isUnlocked)
        #expect(storage.expirationDate == past)
    }
}
