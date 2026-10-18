//
//  PrivacyManifestTests.swift
//  OshiConTests
//

import Foundation
import Testing

/// アプリと Widget Extension のプライバシーマニフェスト。申告が実態と食い違ったら気づけるようにする。
struct PrivacyManifestTests {
    /// アプリと Widget Extension のバンドル。テストはアプリの中で動くので、Bundle.main がアプリになる。
    private static func bundleURLs() throws -> [URL] {
        let widget = try #require(Bundle.main.builtInPlugInsURL).appending(path: "OshiConWidgetExtension.appex")
        return [Bundle.main.bundleURL, widget]
    }

    private static func manifest(in bundleURL: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: bundleURL.appending(path: "PrivacyInfo.xcprivacy"))
        return try #require(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    }

    /// 理由の申告が要る API の種類と理由。
    private static func accessedAPIs(in manifest: [String: Any]) throws -> [String: [String]] {
        let types = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        var result: [String: [String]] = [:]
        for type in types {
            let name = try #require(type["NSPrivacyAccessedAPIType"] as? String)
            result[name] = try #require(type["NSPrivacyAccessedAPITypeReasons"] as? [String])
        }
        return result
    }

    @Test("アプリも Widget Extension もトラッキングせず、データを収集しない")
    func noTrackingAndNoCollection() throws {
        for bundleURL in try Self.bundleURLs() {
            let manifest = try Self.manifest(in: bundleURL)
            #expect(manifest["NSPrivacyTracking"] as? Bool == false, "\(bundleURL.lastPathComponent)")
            #expect((manifest["NSPrivacyTrackingDomains"] as? [Any])?.isEmpty == true, "\(bundleURL.lastPathComponent)")
            #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true, "\(bundleURL.lastPathComponent)")
        }
    }

    @Test("アプリは @AppStorage の UserDefaults（CA92.1）だけを申告する")
    func appAccessedAPIs() throws {
        let manifest = try Self.manifest(in: Bundle.main.bundleURL)
        #expect(try Self.accessedAPIs(in: manifest) == ["NSPrivacyAccessedAPICategoryUserDefaults": ["CA92.1"]])
    }

    @Test("Widget Extension は理由の申告が要る API を使わない")
    func widgetAccessedAPIs() throws {
        let widget = try #require(try Self.bundleURLs().last)
        #expect(try Self.accessedAPIs(in: Self.manifest(in: widget)).isEmpty)
    }
}
