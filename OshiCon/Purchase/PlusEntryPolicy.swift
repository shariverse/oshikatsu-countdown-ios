//
//  PlusEntryPolicy.swift
//  OshiCon
//

import StoreKit
import SwiftUI

/// アプリがどう配られたか。課金画面の入口を出すかを決めるのに使う。
nonisolated enum AppDistribution: Equatable, Sendable {
    /// DEBUG のビルド・Xcode から動かしたもの。
    case development
    case testFlight
    case appStore

    /// ビルドの種類と、StoreKit の取引の環境（`AppTransaction.environment`）から決める。
    /// 環境が分からない（読めない・検証できない）ときは App Store 版として扱う。
    static func resolve(isDebugBuild: Bool, storeEnvironment: AppStore.Environment?) -> Self {
        if isDebugBuild {
            return .development
        }
        switch storeEnvironment {
        case AppStore.Environment.xcode?:
            return .development
        case AppStore.Environment.sandbox?:
            return .testFlight
        default:
            return .appStore
        }
    }
}

/// 課金画面の入口（設定画面の Plus と着せ替えの行、推しの写真ウィジェットから課金画面を開くこと）を出すかの規則。
nonisolated enum PlusEntryPolicy {
    /// 入口を出すか。1.3.0 で Plus を売り始めたので、App Store 版を含むどの配り方でも出す。
    /// 配り方で出し分ける（App Store 版で売るのを止めるなど）ときは、ここだけを替える。
    static func showsEntry(in distribution: AppDistribution) -> Bool {
        switch distribution {
        case .development, .testFlight, .appStore:
            true
        }
    }
}

/// アプリの配り方を見分ける口。画面は `@Environment(\.appDistributionDetector)` から引き、テストや Preview では差し替える。
nonisolated struct AppDistributionDetector: Sendable {
    private let detect: @Sendable () async -> AppDistribution

    init(_ detect: @escaping @Sendable () async -> AppDistribution) {
        self.detect = detect
    }

    func callAsFunction() async -> AppDistribution {
        await detect()
    }

    /// いつも同じ配り方を返す。
    static func fixed(_ distribution: AppDistribution) -> Self {
        Self { distribution }
    }

    /// 端末の中で見分ける（通信しない）。DEBUG のビルドは開発版。ほかは `AppTransaction` の環境（TestFlight は sandbox）で決める。
    /// 起動引数 `-simulateAppStoreDistribution`（`LaunchOptions.simulatesAppStoreDistribution`）のときは、StoreKit に触れずに App Store 版とする。
    static let live = Self {
        if LaunchOptions.simulatesAppStoreDistribution {
            return .appStore
        }
        if AppDistributionDetector.isDebugBuild {
            return .development
        }
        return AppDistribution.resolve(isDebugBuild: false, storeEnvironment: await AppDistributionDetector.storeEnvironment())
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// 検証できた `AppTransaction` の環境。読めない・検証できないときは nil。
    private static func storeEnvironment() async -> AppStore.Environment? {
        guard case let .verified(transaction)? = try? await AppTransaction.shared else {
            return nil
        }
        return transaction.environment
    }
}

extension EnvironmentValues {
    /// アプリの配り方を見分ける口（既定は端末の中で見分ける）。
    @Entry var appDistributionDetector = AppDistributionDetector.live
}
