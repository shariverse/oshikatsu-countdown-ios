//
//  InputText.swift
//  OshiCon
//

import Foundation

/// 入力欄の文字の規則。文字は見た目の 1 文字（書記素クラスタ、Swift の `Character`）で数え、絵文字を途中で切らない。
nonisolated enum InputText {
    /// 連続する空白（改行・全角空白を含む）を半角空白 1 つに潰し、前後の空白を落とす。
    static func collapsingWhitespace(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// 先頭から `maxCount` 文字を取る。
    static func truncated(_ text: String, to maxCount: Int) -> String {
        String(text.prefix(maxCount))
    }

    /// 先頭の見た目の 1 文字。アバターの頭文字に使う。空なら空文字。
    static func firstCharacter(of text: String) -> String {
        truncated(collapsingWhitespace(text), to: 1)
    }
}

/// 文字を入力する欄と、その上限・必須。
nonisolated enum InputField: CaseIterable, Sendable {
    /// 予定のタイトル
    case eventTitle
    /// 予定の会場・場所
    case eventVenue
    /// 推しの名前
    case oshiName

    /// 上限の文字数（空白を潰した後）。
    var maxLength: Int {
        switch self {
        case .eventTitle, .eventVenue:
            40
        case .oshiName:
            20
        }
    }

    var isRequired: Bool {
        switch self {
        case .eventTitle, .oshiName:
            true
        case .eventVenue:
            false
        }
    }

    /// 入力中の値。上限で切るだけで、空白は潰さない（打っている途中の空白を消さないため）。
    func limited(_ text: String) -> String {
        InputText.truncated(text, to: maxLength)
    }

    /// 保存する値。空白を潰してから上限で切る。切った末尾が空白になったら、それも落とす。
    func normalized(_ text: String) -> String {
        let truncated = InputText.truncated(InputText.collapsingWhitespace(text), to: maxLength)
        return InputText.collapsingWhitespace(truncated)
    }

    /// 保存できる値か。必須の欄は、空白だけなら空とみなして保存できない。
    func isValid(_ text: String) -> Bool {
        !isRequired || !normalized(text).isEmpty
    }
}
