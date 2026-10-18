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
        #expect(AppTab.allCases.map { $0.title(locale: DomainFixtures.japanese) } == ["ホーム", "推し", "設定"])
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
        #expect(router.sheetDismissal == SheetDismissal(count: 1, keepsAddEvent: true))

        // 予定の詳細を開くときは、予定の追加の要求を取り消し、開いているシートを閉じさせる
        let id = UUID()
        router.open(.eventDetail(id), hasCompletedOnboarding: true)
        #expect(!router.pendingAddEvent)
        #expect(router.sheetDismissal == SheetDismissal(count: 2, keepsAddEvent: false))
        #expect(router.homePath == [.eventDetail(id)])

        // アプリを開くだけのリンクでは、開いているシートは閉じない
        router.open(.home, hasCompletedOnboarding: true)
        #expect(router.sheetDismissal == SheetDismissal(count: 2, keepsAddEvent: false))
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
        #expect(router.sheetDismissal == SheetDismissal())
    }

    /// 対応する 12 言語。英語を既定にする。
    private static let languages = ["en", "ja", "zh-Hans", "zh-Hant", "ko", "fr", "de", "es", "pt-BR", "it", "th", "id"]

    @Test(
        "ホーム画面の表示名は言語ごとに訳す（日本語は「推し活カウント」）",
        arguments: [("en", "Oshi Countdown"), ("ja", "推し活カウント"), ("zh-Hant", "推活倒數"), ("ko", "최애 디데이")]
    )
    func displayName(language: String, name: String) throws {
        let path = try #require(Bundle.main.path(forResource: "InfoPlist", ofType: "strings", inDirectory: nil, forLocalization: language))
        let strings = try #require(NSDictionary(contentsOfFile: path))
        #expect(strings["CFBundleDisplayName"] as? String == name)
    }

    @Test("アプリの言語は英語を既定に 12 言語")
    func languages() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleDevelopmentRegion") as? String == "en")
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleLocalizations") as? [String] == Self.languages)
        #expect(Set(Self.languages).isSubset(of: Set(Bundle.main.localizations)))
        #expect(Self.languages.contains(Bundle.main.preferredLocalizations.first ?? ""))
        #expect(Locale(identifier: "en_US").twentyFourHour.hourCycle == .zeroToTwentyThree)
    }

    @Test(
        "画面の locale は、言語をアプリが選んだ言語にし、地域は端末の地域を残す",
        arguments: [
            ("zh-Hant", "en_JP", Locale.LanguageCode.chinese, Locale.Region.japan),
            ("ja", "en_US", .japanese, .unitedStates),
            ("en", "de_DE", .english, .germany),
            // 端末の地域の上書き（rg）も残す
            ("en", "de_DE@rg=gbzzzz", .english, .unitedKingdom),
            // 言語が地域を持つときは言語の地域
            ("pt-BR", "en_US", .portuguese, .brazil)
        ]
    )
    func appLocale(language: String, base: String, languageCode: Locale.LanguageCode, region: Locale.Region) {
        let locale = Locale.app(language: language, base: Locale(identifier: base))
        #expect(locale.language.languageCode == languageCode)
        #expect(locale.region == region)
    }

    @Test("端末に地域が無いときは、言語だけ差し替えて地域なしのまま")
    func appLocaleWithoutRegion() {
        let locale = Locale.app(language: "zh-Hant", base: Locale(identifier: "en"))
        #expect(locale.language.languageCode == .chinese)
        #expect(locale.language.script == .hanTraditional)
        #expect(locale.region == nil)
        #expect(!locale.isJapanese)
        #expect(Locale.app(language: "ja", base: Locale(identifier: "en")).isJapanese)
    }
}
