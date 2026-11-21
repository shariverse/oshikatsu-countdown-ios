//
//  PlusPurchaseOutcome.swift
//  OshiCon
//

import StoreKit

/// 課金画面での購入の結果（`onInAppPurchaseCompletion` が渡す値）を、画面がすることごとに分けたもの。
nonisolated enum PlusPurchaseOutcome {
    /// 購入が終わった。取引を `PlusStore.process(_:)` に渡す（検証・finish・判定のし直し）。
    case purchased(VerificationResult<StoreKit.Transaction>)
    /// 承認を待っている（Ask to Buy など）。承認されると取引は `Transaction.updates` に届く。
    case pending
    /// 自分で取り消した。何も出さない。
    case cancelled
    /// 失敗した。
    case failed

    init(_ result: Result<Product.PurchaseResult, any Error>) {
        switch result {
        case let .success(purchase):
            switch purchase {
            case let .success(verification):
                self = .purchased(verification)
            case .pending:
                self = .pending
            case .userCancelled:
                self = .cancelled
            @unknown default:
                self = .failed
            }
        case let .failure(error):
            // 支払いのシートを閉じたときに、エラーとして届くことがある
            if case .userCancelled = error as? StoreKitError {
                self = .cancelled
            } else {
                self = .failed
            }
        }
    }
}

/// 課金画面から開くリンク。
nonisolated enum PlusLegalLink {
    /// 利用規約。App Store Connect で独自の EULA を入れていないので、Apple の標準の使用許諾契約（EULA）。
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// プライバシーポリシー。公開先が決まるまでは、リポジトリの `docs/app-store/privacy-policy.md` を指す。
    /// 公開したら、この定数だけを差し替える（App Store Connect の「プライバシーポリシー URL」と同じ URL にする）。
    static let privacyPolicy = URL(
        string: "https://github.com/shariverse/oshikatsu-countdown-ios/blob/develop/docs/app-store/privacy-policy.md"
    )!
}
