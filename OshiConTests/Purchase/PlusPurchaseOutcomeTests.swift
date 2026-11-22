//
//  PlusPurchaseOutcomeTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import StoreKit
import Testing

struct PlusPurchaseOutcomeTests {
    private struct SomeError: Error {}

    /// 結果の種類（取引の中身は比べない）。
    private func kind(_ outcome: PlusPurchaseOutcome) -> String {
        switch outcome {
        case .purchased:
            "purchased"
        case .pending:
            "pending"
        case .cancelled:
            "cancelled"
        case .failed:
            "failed"
        }
    }

    @Test("承認待ち（Ask to Buy）は保留として扱う")
    func pending() {
        #expect(kind(PlusPurchaseOutcome(.success(.pending))) == "pending")
    }

    @Test("自分で取り消したときは何も出さない")
    func userCancelled() {
        #expect(kind(PlusPurchaseOutcome(.success(.userCancelled))) == "cancelled")
        #expect(kind(PlusPurchaseOutcome(.failure(StoreKitError.userCancelled))) == "cancelled")
    }

    @Test("ほかのエラーは失敗として扱う")
    func failed() {
        #expect(kind(PlusPurchaseOutcome(.failure(SomeError()))) == "failed")
        #expect(kind(PlusPurchaseOutcome(.failure(StoreKitError.notAvailableInStorefront))) == "failed")
        #expect(kind(PlusPurchaseOutcome(.failure(Product.PurchaseError.productUnavailable))) == "failed")
    }

    @Test("利用規約は Apple の標準の EULA、プライバシーポリシーは https の URL")
    func legalLinks() {
        #expect(PlusLegalLink.termsOfUse.absoluteString == "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
        #expect(PlusLegalLink.privacyPolicy.scheme == "https")
    }
}
