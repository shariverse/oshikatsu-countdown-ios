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

    @Test("ウィジェットのリンクで予定の詳細をホームのタブに積み、アプリを開くだけのリンクはホームのタブにする")
    func openWidgetLink() {
        let router = AppRouter()
        router.selectedTab = .oshi
        let id = UUID()
        router.open(.eventDetail(id), hasCompletedOnboarding: true)
        #expect(router.selectedTab == .home)
        #expect(router.homePath == [.eventDetail(id)])

        router.selectedTab = .settings
        router.open(.home, hasCompletedOnboarding: true)
        #expect(router.selectedTab == .home)
        #expect(router.homePath == [.eventDetail(id)])
    }

    @Test("予定の追加のリンクで、ホームの最初の画面に戻して予定の追加のシートを開く")
    func openAddEventLink() {
        let router = AppRouter()
        router.selectedTab = .oshi
        router.homePath = [.eventDetail(UUID())]
        router.open(.addEvent, hasCompletedOnboarding: true)
        #expect(router.selectedTab == .home)
        #expect(router.homePath.isEmpty)
        #expect(router.pendingAddEvent)
        #expect(router.sheetDismissal == 1)

        // 予定の詳細を開くときは、予定の追加の要求を取り消し、開いているシートを閉じさせる
        let id = UUID()
        router.open(.eventDetail(id), hasCompletedOnboarding: true)
        #expect(!router.pendingAddEvent)
        #expect(router.sheetDismissal == 2)
        #expect(router.homePath == [.eventDetail(id)])

        // アプリを開くだけのリンクでは、開いているシートは閉じない
        router.open(.home, hasCompletedOnboarding: true)
        #expect(router.sheetDismissal == 2)
    }

    @Test("初回の導線の途中は、ウィジェットのリンクで何も開かない")
    func widgetLinkDuringOnboarding() {
        let router = AppRouter()
        router.selectedTab = .settings
        let shown = HomeRoute.eventDetail(UUID())
        router.homePath = [shown]
        for link in [WidgetLink.eventDetail(UUID()), .addEvent, .home] {
            router.open(link, hasCompletedOnboarding: false)
        }
        #expect(router.selectedTab == .settings)
        #expect(router.homePath == [shown])
        #expect(!router.pendingAddEvent)
        #expect(router.sheetDismissal == 0)
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
