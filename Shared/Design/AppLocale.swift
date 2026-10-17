//
//  AppLocale.swift
//  OshiCon
//

import Foundation

extension Locale {
    /// アプリの画面に使う locale。文言は日本語だけなので、端末の言語・地域にかかわらず日本の書き方で日付や時刻を出す
    /// （英語の端末では「10/18/26」のような米国の書き方になるため）。
    nonisolated static let app = Locale(identifier: "ja_JP")

    /// 24 時間表記にした `app`。開始時刻は端末の設定にかかわらず 24 時間表記で出す（SPEC の 2.5）。
    nonisolated static let app24Hour: Locale = {
        var components = Locale.Components(locale: app)
        components.hourCycle = .zeroToTwentyThree
        return Locale(components: components)
    }()
}
