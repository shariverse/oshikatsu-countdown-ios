//
//  OshiFormTests.swift
//  OshiConTests
//

@testable import OshiCon
import Testing

struct OshiFormTests {
    @Test("新しく登録するときは名前が空で、推し色は既定の色")
    func newOshi() {
        let form = OshiForm(oshi: nil)
        #expect(form.name.isEmpty)
        #expect(form.color == .defaultColor)
        #expect(!form.canSave)
    }

    @Test("編集するときは推しの名前と推し色から始める")
    func editingOshi() {
        let form = OshiForm(oshi: Oshi(name: "ミナト", color: .navy))
        #expect(form.name == "ミナト")
        #expect(form.color == .navy)
        #expect(form.canSave)
    }

    @Test(
        "名前は空白を潰した後の見た目の文字数で数え、空白だけ・20 文字を超えると保存できない",
        arguments: [
            ("", 0, false),
            ("　 \n", 0, false),
            ("ミナト", 3, true),
            ("  ミ   ナト  ", 4, true),
            (String(repeating: "あ", count: 20), 20, true),
            (String(repeating: "あ", count: 21), 21, false),
            (String(repeating: "👨‍👩‍👧", count: 20), 20, true),
            (String(repeating: "あ", count: 20) + "   ", 20, true)
        ]
    )
    func nameRules(name: String, length: Int, canSave: Bool) {
        var form = OshiForm(oshi: nil)
        form.name = name
        #expect(form.nameLength == length)
        #expect(form.isNameTooLong == (length > 20))
        #expect(form.canSave == canSave)
    }

    @Test("削除の確認は、一緒に消える予定があればその件数を出す")
    func deleteConfirmation() {
        #expect(OshiForm.deleteTitle(name: "ミナト", locale: DomainFixtures.japanese) == "「ミナト」を削除しますか？")
        #expect(OshiForm.deleteMessage(eventCount: 0, locale: DomainFixtures.japanese) == "元に戻せません。")
        #expect(OshiForm.deleteMessage(eventCount: 3, locale: DomainFixtures.japanese) == "この推しの予定 3 件も削除されます。元に戻せません。")
    }

    @Test("削除の確認は英語では件数で単数・複数を変える")
    func englishDeleteTexts() {
        let en = DomainFixtures.english
        #expect(OshiForm.deleteTitle(name: "Minato", locale: en) == "Delete \u{201C}Minato\u{201D}?")
        #expect(OshiForm.deleteMessage(eventCount: 1, locale: en) == "This oshi's 1 event will also be deleted. This can't be undone.")
        #expect(OshiForm.deleteMessage(eventCount: 3, locale: en) == "This oshi's 3 events will also be deleted. This can't be undone.")
    }
}
