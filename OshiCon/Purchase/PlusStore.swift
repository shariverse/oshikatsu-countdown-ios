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
/// UI テスト・スクリーンショット（メモリ上のストア）では StoreKit に触れず、App Group にも書かない。
/// Plus の状態は起動引数で固定する（既定と `-plusLocked` は使えない、`-plusUnlocked` は使える。`LaunchOptions.unlocksPlus`）。
@Observable
final class PlusStore {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "PlusStore")

    /// Plus が使えるか。画面は `\.isPlusUnlocked` から引く。
    private(set) var isUnlocked: Bool
    /// 自動で更新されるサブスクリプションがあるか（`PlusLifetimeGuidance`）。課金画面の買い切りの注記と購入後の案内に使う。
    /// App Group には書かない。
    private(set) var hasRenewingSubscription: Bool

    @ObservationIgnored private let isActive: Bool
    @ObservationIgnored private let storage: PlusStatusStorage
    /// `Transaction.updates` の監視。ストアはアプリが動いている間ずっと残るので、止めない。
    @ObservationIgnored private var updates: Task<Void, Never>?
    /// 決め直しの番号。続けて決め直したとき、先に始めたほうの結果で後のほうの結果を上書きしない。
    @ObservationIgnored private var generation = 0

    /// - Parameters:
    ///   - isActive: StoreKit から決めるか。false（メモリ上のストア）のときは `unlocksWhenInactive` に固定する
    ///   - unlocksWhenInactive: StoreKit に触れないときの Plus の状態（起動引数 `-plusUnlocked`）
    ///   - subscribesWhenInactive: StoreKit に触れないときに、自動で更新されるサブスクリプションがあるとするか（Preview 用）。
    ///     true にすると Plus も使える状態にする
    init(
        isActive: Bool = !LaunchOptions.usesInMemoryStore,
        unlocksWhenInactive: Bool = LaunchOptions.unlocksPlus,
        subscribesWhenInactive: Bool = false,
        storage: PlusStatusStorage = .appGroup
    ) {
        self.isActive = isActive
        self.storage = storage
        guard isActive else {
            isUnlocked = unlocksWhenInactive || subscribesWhenInactive
            hasRenewingSubscription = subscribesWhenInactive
            return
        }
        // StoreKit から読み終わるまでは、前に決めた結果を使う（起動の直後に見た目が切り替わらないように）
        isUnlocked = storage.isUnlocked
        hasRenewingSubscription = false
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
        let purchases = await PlusTransactions.currentPurchases()
        guard current == generation else {
            return
        }
        let now = Date.now
        hasRenewingSubscription = PlusLifetimeGuidance.hasRenewingSubscription(purchases: purchases, now: now)
        apply(
            PlusEntitlement.isUnlocked(purchases: purchases, now: now),
            expirationDate: PlusEntitlement.expirationDate(purchases: purchases, now: now)
        )
    }

    private func apply(_ unlocked: Bool, expirationDate: Date?) {
        isUnlocked = unlocked
        guard storage.write(isUnlocked: unlocked, expirationDate: expirationDate) else {
            return
        }
        // Plus の状態か期限で変わるウィジェットを描き直す
        WidgetCenter.shared.reloadAllTimelines()
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
