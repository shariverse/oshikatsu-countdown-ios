//
//  PlusStore.swift
//  OshiCon
//

import Observation
import os
import StoreKit
import SwiftUI
import WidgetKit

/// 推し活カウントダウン Plus の購入の状態。StoreKit 2 の取引から「Plus が使えるか」を決め（`PlusEntitlement`）、
/// App Group の UserDefaults（`PlusStatusStorage`）に書いて Widget Extension にも渡す。
///
/// - 起動したとき（作ったとき）と、アプリが前面に来たとき（期限を過ぎたのに気づく）に `Transaction.currentEntitlements` から決め直す
/// - `Transaction.updates`（ほかの端末での購入・更新・返金・Ask to Buy の承認など）を受けたら、finish してから決め直す
/// - 検証済みの取引だけを数える。通信はせず、確かめるのは StoreKit が端末の中でする検証だけ
///
/// UI テスト・スクリーンショット（メモリ上のストア）では StoreKit に触れず、App Group にも書かない（使えない状態のまま）。
@Observable
final class PlusStore {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "PlusStore")

    /// Plus が使えるか。画面は `\.isPlusUnlocked` から引く。
    private(set) var isUnlocked: Bool

    @ObservationIgnored private let isActive: Bool
    @ObservationIgnored private let storage: PlusStatusStorage
    /// `Transaction.updates` の監視。ストアはアプリが動いている間ずっと残るので、止めない。
    @ObservationIgnored private var updates: Task<Void, Never>?
    /// 決め直しの番号。続けて決め直したとき、先に始めたほうの結果で後のほうの結果を上書きしない。
    @ObservationIgnored private var generation = 0

    init(isActive: Bool = !LaunchOptions.usesInMemoryStore, storage: PlusStatusStorage = .appGroup) {
        self.isActive = isActive
        self.storage = storage
        // StoreKit から読み終わるまでは、前に決めた結果を使う（起動の直後に見た目が切り替わらないように）
        isUnlocked = isActive && storage.isUnlocked
        guard isActive else {
            return
        }
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.process(result)
            }
        }
        Task {
            await refresh()
        }
    }

    /// 取引を受け取る（`Transaction.updates` と、課金画面での購入の結果）。検証済みなら finish し、決め直す。
    /// 検証できなかった取引は数えず、finish もしない。
    func process(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard isActive else {
            return
        }
        switch result {
        case let .verified(transaction):
            await transaction.finish()
            await refresh()
        case let .unverified(transaction, error):
            Self.logger.error(
                "検証できない取引を受け取った（\(transaction.productID, privacy: .public)）: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    /// `Transaction.currentEntitlements` から決め直し、App Group に書く（購入の復元の後にも呼ぶ）。
    func refresh() async {
        guard isActive else {
            return
        }
        generation += 1
        let current = generation
        let purchases = await Self.currentPurchases()
        guard current == generation else {
            return
        }
        apply(PlusEntitlement.isUnlocked(purchases: purchases, now: .now))
    }

    private func apply(_ unlocked: Bool) {
        isUnlocked = unlocked
        guard storage.isUnlocked != unlocked else {
            return
        }
        storage.isUnlocked = unlocked
        // Plus で変わるウィジェットを描き直す
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 今の権利（Plus の商品の、検証済みの取引）を購入の記録に写す。
    private static func currentPurchases() async -> [PlusPurchase] {
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
        // 猶予期間中は取引の期限を過ぎているので、更新の情報から猶予期間の終わりを読む
        if transaction.productType == .autoRenewable,
           let status = await transaction.subscriptionStatus,
           case let .verified(renewalInfo) = status.renewalInfo {
            gracePeriodExpirationDate = renewalInfo.gracePeriodExpirationDate
        }
        return PlusPurchase(
            productID: transaction.productID,
            expirationDate: transaction.expirationDate,
            revocationDate: transaction.revocationDate,
            gracePeriodExpirationDate: gracePeriodExpirationDate
        )
    }
}

/// Plus の購入の状態を画面に配る。アプリが前面に来たときに決め直す（開いている間に期限を過ぎたときのため）。
struct PlusStatusProvider: ViewModifier {
    let store: PlusStore

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .environment(store)
            .environment(\.isPlusUnlocked, store.isUnlocked)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        await store.refresh()
                    }
                }
            }
    }
}

extension View {
    /// Plus の購入の状態を配る。画面は `\.isPlusUnlocked` で Plus が使えるかを、`PlusStore` で決め直し・取引の受け取りを引く。
    func providesPlusStatus(_ store: PlusStore) -> some View {
        modifier(PlusStatusProvider(store: store))
    }
}
