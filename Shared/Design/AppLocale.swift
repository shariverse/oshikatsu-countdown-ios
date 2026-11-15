//
//  AppLocale.swift
//  OshiCon
//

import Foundation

extension Locale {
    /// アプリの画面に使う locale。言語はアプリが選んだ localization（対応していない言語の端末では英語）、地域・暦などは端末の設定。
    /// 端末の言語をそのまま使うと、対応していない言語の端末で文言は英語なのに日付だけその言語になるため、言語をそろえる。
    nonisolated static var app: Locale {
        app(language: Bundle.main.preferredLocalizations.first ?? "en", base: .current)
    }

    /// `base` の地域・暦などを残し、言語だけ `language`（`ja`・`zh-Hant` など）にした locale。
    /// 地域は言語の中にも入っているので、言語を差し替えるときに `base` の地域を移す（`pt-BR` のように言語が地域を持つときはそれを使う）。
    /// `base` に地域が無ければ地域なしのまま。
    nonisolated static func app(language: String, base: Locale) -> Locale {
        var components = Locale.Components(locale: base)
        var languageComponents = Locale.Language.Components(identifier: language)
        if languageComponents.region == nil {
            languageComponents.region = base.region
        }
        components.languageComponents = languageComponents
        return Locale(components: components)
    }

    /// 24 時間表記にした `app`。開始時刻は端末の設定にかかわらず 24 時間表記で出す（SPEC の 2.5）。
    nonisolated static var app24Hour: Locale {
        app.twentyFourHour
    }

    /// 24 時間表記にした locale。
    nonisolated var twentyFourHour: Locale {
        var components = Locale.Components(locale: self)
        components.hourCycle = .zeroToTwentyThree
        return Locale(components: components)
    }

    /// 日本語か。本文にテーマの書体を使うかを決める。
    nonisolated var isJapanese: Bool {
        language.languageCode == .japanese
    }
}
