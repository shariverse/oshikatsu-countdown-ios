//
//  InAppSafariPageTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct InAppSafariPageTests {
    @Test("http・https のページは、アプリの中の Safari の画面で開く", arguments: [
        "https://shilokuma.jp/privacy/oshikatsu-countdown/",
        "http://example.com/",
        "HTTPS://EXAMPLE.COM/"
    ])
    func webPage(_ string: String) throws {
        let url = try #require(URL(string: string))
        #expect(InAppSafariPage(url: url)?.url == url)
    }

    @Test("http・https 以外（設定アプリ・メール・アプリ自身のリンク）は、システムに渡す", arguments: [
        "app-settings:",
        "mailto:support@example.com",
        "oshicon://home",
        "file:///tmp/a.html"
    ])
    func otherScheme(_ string: String) throws {
        let url = try #require(URL(string: string))
        #expect(InAppSafariPage(url: url) == nil)
    }

    @Test("課金画面の利用規約・プライバシーポリシーは、アプリの中の Safari の画面で開ける")
    func legalLinks() {
        #expect(InAppSafariPage(url: PlusLegalLink.termsOfUse) != nil)
        #expect(InAppSafariPage(url: PlusLegalLink.privacyPolicy) != nil)
    }
}
