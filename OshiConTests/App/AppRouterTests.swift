//
//  AppRouterTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct AppRouterTests {
    @Test("タブはホーム・推し・設定の 3 つ")
    func tabs() {
        #expect(AppTab.allCases.map(\.title) == ["ホーム", "推し", "設定"])
    }

    @Test("ホームに積むときは、ホームのタブに切り替えて最初の画面まで戻してから積む")
    func openInHome() {
        let router = AppRouter()
        router.selectedTab = .settings
        router.homePath = [.eventDetail(UUID()), .eventDetail(UUID())]

        let id = UUID()
        router.openInHome(.eventDetail(id))
        #expect(router.selectedTab == .home)
        #expect(router.homePath == [.eventDetail(id)])
    }

    @Test("ホーム画面の表示名")
    func displayName() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String == "推し活カウント")
    }

    /// 文言は日本語だけ。端末の言語が英語などでも、日付の選択やシステムのボタンを日本語で出す。
    @Test("アプリの言語は日本語だけ")
    func japaneseOnly() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleDevelopmentRegion") as? String == "ja")
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleLocalizations") as? [String] == ["ja"])
        #expect(Bundle.main.preferredLocalizations.first == "ja")
        #expect(Locale.app.identifier == "ja_JP")
    }
}
