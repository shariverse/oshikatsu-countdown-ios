//
//  StoreKitConfigurationTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

/// StoreKit Configuration ファイル（`Configs/OshiCon.storekit`）が、商品の正（`docs/app-store/in-app-purchases.json`）と食い違わないか。
/// どちらもアプリに入らないファイルなので、リポジトリから読む（Simulator はホストのファイルを読める）。
struct StoreKitConfigurationTests {
    private typealias Object = [String: Any]

    /// リポジトリの最上位（このファイルは OshiConTests/Purchase/ にある）。
    private static let repository = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static func object(at path: String) throws -> Object {
        let data = try Data(contentsOf: repository.appending(path: path))
        return try #require(try JSONSerialization.jsonObject(with: data) as? Object)
    }

    private static func objects(_ value: Any?) throws -> [Object] {
        try #require(value as? [Object])
    }

    private static func purchases() throws -> Object {
        try object(at: "docs/app-store/in-app-purchases.json")
    }

    private static func storeKit() throws -> Object {
        try object(at: "Configs/OshiCon.storekit")
    }

    /// in-app-purchases.json の言語コードから .storekit のロケール（App Store Connect のロケールの - を _ にしたもの）へ。
    private static func storeKitLocales() throws -> [String: String] {
        let languages = try objects(try object(at: "docs/app-store/languages.json")["languages"])
        var locales: [String: String] = [:]
        for language in languages {
            let code = try #require(language["language"] as? String)
            let storeLocale = try #require(language["storeLocale"] as? String)
            locales[code] = storeLocale.replacingOccurrences(of: "-", with: "_")
        }
        return locales
    }

    /// in-app-purchases.json の表示名（と説明）を、.storekit のロケールごとの値にする。
    private static func expectedLocalizations(_ value: Any?, includesDescription: Bool) throws -> [String: [String]] {
        let localizations = try #require(value as? [String: Object])
        let locales = try storeKitLocales()
        var expected: [String: [String]] = [:]
        for (language, localization) in localizations {
            let locale = try #require(locales[language])
            let name = try #require(localization["name"] as? String)
            if includesDescription {
                expected[locale] = [name, try #require(localization["description"] as? String)]
            } else {
                expected[locale] = [name]
            }
        }
        return expected
    }

    private static func actualLocalizations(_ value: Any?, includesDescription: Bool) throws -> [String: [String]] {
        var actual: [String: [String]] = [:]
        for localization in try objects(value) {
            let locale = try #require(localization["locale"] as? String)
            let name = try #require(localization["displayName"] as? String)
            if includesDescription {
                actual[locale] = [name, try #require(localization["description"] as? String)]
            } else {
                actual[locale] = [name]
            }
        }
        return actual
    }

    private static let periods = ["ONE_WEEK": "P1W", "ONE_MONTH": "P1M", "ONE_YEAR": "P1Y"]

    @Test("商品は 3 つで、productId がアプリの定数（PlusProduct）と同じ")
    func productIDs() throws {
        let storeKit = try Self.storeKit()
        let group = try #require(try Self.objects(storeKit["subscriptionGroups"]).first)
        let subscriptions = try Self.objects(group["subscriptions"]).compactMap { $0["productID"] as? String }
        let products = try Self.objects(storeKit["products"]).compactMap { $0["productID"] as? String }
        #expect(Set(subscriptions) == Set(PlusProduct.subscriptionIDs))
        #expect(Set(subscriptions + products) == Set(PlusProduct.allIDs))
        #expect(subscriptions.count + products.count == PlusProduct.allCases.count)
    }

    @Test("サブスクリプショングループの名前と表示名（12 言語）が同じ")
    func subscriptionGroup() throws {
        let expected = try #require(try Self.purchases()["subscriptionGroup"] as? Object)
        let groups = try Self.objects(try Self.storeKit()["subscriptionGroups"])
        #expect(groups.count == 1)
        let group = try #require(groups.first)
        #expect(group["name"] as? String == expected["referenceName"] as? String)
        let localizations = try Self.actualLocalizations(group["localizations"], includesDescription: false)
        let expectedLocalizations = try Self.expectedLocalizations(expected["localizations"], includesDescription: false)
        #expect(localizations.count == 12)
        #expect(localizations == expectedLocalizations)
    }

    @Test("サブスクリプションの価格・期間・お試し・ファミリー共有・表示名（12 言語）が同じ")
    func subscriptions() throws {
        let group = try #require(try Self.objects(try Self.storeKit()["subscriptionGroups"]).first)
        let actual = try Self.objects(group["subscriptions"])
        let expected = try Self.objects(try Self.purchases()["subscriptions"])
        #expect(actual.count == expected.count)
        for subscription in expected {
            let productID = try #require(subscription["productId"] as? String)
            let product = try #require(actual.first { $0["productID"] as? String == productID })
            #expect(product["type"] as? String == "RecurringSubscription")
            #expect(product["referenceName"] as? String == subscription["referenceName"] as? String)
            #expect(product["displayPrice"] as? String == subscription["price"] as? String)
            #expect(product["familyShareable"] as? Bool == subscription["familySharable"] as? Bool)
            #expect(product["groupNumber"] as? Int == subscription["groupLevel"] as? Int)
            #expect(product["subscriptionGroupID"] as? String == group["id"] as? String)
            let period = try #require(subscription["period"] as? String)
            #expect(product["recurringSubscriptionPeriod"] as? String == Self.periods[period])
            if let offer = subscription["introductoryOffer"] as? Object {
                let actualOffer = try #require(product["introductoryOffer"] as? Object)
                #expect(offer["offerMode"] as? String == "FREE_TRIAL")
                #expect(actualOffer["paymentMode"] as? String == "free")
                let duration = try #require(offer["duration"] as? String)
                #expect(actualOffer["subscriptionPeriod"] as? String == Self.periods[duration])
            } else {
                #expect(product["introductoryOffer"] == nil)
            }
            let localizations = try Self.actualLocalizations(product["localizations"], includesDescription: true)
            let expectedLocalizations = try Self.expectedLocalizations(subscription["localizations"], includesDescription: true)
            #expect(localizations.count == 12)
            #expect(localizations == expectedLocalizations)
        }
    }

    @Test("買い切り（非消耗型）の価格・ファミリー共有・表示名（12 言語）が同じ")
    func lifetime() throws {
        let actual = try Self.objects(try Self.storeKit()["products"])
        let expected = try Self.objects(try Self.purchases()["inAppPurchases"])
        #expect(actual.count == expected.count)
        for purchase in expected {
            let productID = try #require(purchase["productId"] as? String)
            let product = try #require(actual.first { $0["productID"] as? String == productID })
            #expect(purchase["type"] as? String == "NON_CONSUMABLE")
            #expect(product["type"] as? String == "NonConsumable")
            #expect(product["referenceName"] as? String == purchase["referenceName"] as? String)
            #expect(product["displayPrice"] as? String == purchase["price"] as? String)
            #expect(product["familyShareable"] as? Bool == purchase["familySharable"] as? Bool)
            let localizations = try Self.actualLocalizations(product["localizations"], includesDescription: true)
            let expectedLocalizations = try Self.expectedLocalizations(purchase["localizations"], includesDescription: true)
            #expect(localizations.count == 12)
            #expect(localizations == expectedLocalizations)
        }
    }

    @Test("ストアフロントは日本（価格の正は日本の税込み価格）")
    func storefront() throws {
        let settings = try #require(try Self.storeKit()["settings"] as? Object)
        #expect(settings["_storefront"] as? String == "JPN")
    }

    @Test("共有スキーム OshiCon の Run とテストプランで、この StoreKit Configuration ファイルを使う")
    func schemeUsesConfiguration() throws {
        let scheme = try String(
            contentsOf: Self.repository.appending(path: "OshiCon.xcodeproj/xcshareddata/xcschemes/OshiCon.xcscheme"),
            encoding: .utf8
        )
        // スキームのパスは xcshareddata からの相対
        #expect(scheme.contains("identifier = \"../../Configs/OshiCon.storekit\""))
        #expect(scheme.contains("reference = \"container:OshiCon.xctestplan\""))

        // テストプランのパスはテストプランのファイルからの相対
        let plan = try Self.object(at: "OshiCon.xctestplan")
        let options = try #require(plan["defaultOptions"] as? Object)
        let reference = try #require(options["storeKitConfigurationFileReference"] as? Object)
        #expect(reference["identifier"] as? String == "Configs/OshiCon.storekit")
        let targets = try Self.objects(plan["testTargets"]).compactMap { ($0["target"] as? Object)?["name"] as? String }
        #expect(Set(targets) == ["OshiConTests", "OshiConUITests"])
    }
}
