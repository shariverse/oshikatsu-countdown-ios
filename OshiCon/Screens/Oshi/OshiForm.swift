//
//  OshiForm.swift
//  OshiCon
//

import Foundation

/// 推しの登録・編集の入力と、その規則（画面から切り離してテストする）。
///
/// 名前は打っている途中では切らない。日本語の変換中（確定前の文字）を上限で切ると、変換が壊れるため。
/// 上限を超えたら文字数を赤く出して（`InputLengthFooter`）保存できないようにし、削ってもらう。
nonisolated struct OshiForm: Equatable, Sendable {
    var name: String
    var color: OshiColor

    /// 新しく登録するときは `oshi` に nil を渡す。
    init(oshi: Oshi?) {
        name = oshi?.name ?? ""
        color = oshi?.color ?? .defaultColor
    }

    /// 名前の文字数（空白を潰した後の、見た目の 1 文字の数）。
    var nameLength: Int {
        InputField.oshiName.length(of: name)
    }

    var isNameTooLong: Bool {
        InputField.oshiName.exceedsLimit(name)
    }

    /// 保存できるか。名前が空白だけ・上限を超えるときは保存できない。
    var canSave: Bool {
        InputField.oshiName.isValid(name) && !isNameTooLong
    }

    /// 削除の確認の見出し。
    static func deleteTitle(name: String, locale: Locale = .app) -> String {
        String(localized: LocalizedStringResource("「\(name)」を削除しますか？", locale: locale))
    }

    /// 削除の確認の本文。一緒に消える予定があればその件数を出す。
    static func deleteMessage(eventCount: Int, locale: Locale = .app) -> String {
        eventCount > 0
            ? String(localized: LocalizedStringResource("この推しの予定 \(eventCount) 件も削除されます。元に戻せません。", locale: locale))
            : String(localized: LocalizedStringResource("元に戻せません。", locale: locale))
    }
}
