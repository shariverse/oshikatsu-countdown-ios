//
//  InputTextTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct InputTextTests {
    private static let family = "👨‍👩‍👧"

    @Test(
        "連続する空白（改行・全角空白を含む）を 1 つに潰し、前後を落とす",
        arguments: [
            ("　ミナト\n\n くん  ", "ミナト くん"),
            (" 東京ドーム ", "東京ドーム"),
            ("A\tB\r\nC\u{00A0}D", "A B C D"),
            ("   ", ""),
            ("", "")
        ]
    )
    func collapsesWhitespace(input: String, expected: String) {
        #expect(InputText.collapsingWhitespace(input) == expected)
    }

    @Test("文字は見た目の 1 文字で数え、絵文字を途中で切らない")
    func truncatesByGraphemeCluster() {
        let title = String(repeating: "a", count: 39) + Self.family + "b"
        #expect(InputText.truncated(title, to: 40) == String(repeating: "a", count: 39) + Self.family)
        #expect(InputText.truncated("🇯🇵🇯🇵", to: 1) == "🇯🇵")
        #expect(InputText.truncated("が", to: 1) == "が")
        #expect(InputText.truncated("短い", to: 40) == "短い")
    }

    @Test("頭文字は見た目の 1 文字")
    func firstCharacter() {
        #expect(InputText.firstCharacter(of: Self.family + "と一緒") == Self.family)
        #expect(InputText.firstCharacter(of: "LUMINA") == "L")
        #expect(InputText.firstCharacter(of: "　ミナト") == "ミ")
        #expect(InputText.firstCharacter(of: "").isEmpty)
    }

    @Test("上限はタイトル 40 文字・会場 40 文字・推しの名前 20 文字")
    func maxLengths() {
        #expect(InputField.eventTitle.maxLength == 40)
        #expect(InputField.eventVenue.maxLength == 40)
        #expect(InputField.oshiName.maxLength == 20)
    }

    @Test("保存する値は空白を潰してから上限で切る", arguments: InputField.allCases)
    func normalizedCollapsesThenTruncates(field: InputField) {
        let long = String(repeating: "あ", count: field.maxLength + 5)
        #expect(field.normalized(long) == String(repeating: "あ", count: field.maxLength))
        // 空白を潰した後で数えるので、潰す前に上限を超えていても上限ちょうどまで残る
        let spaced = String(repeating: "あ  ", count: 5) + String(repeating: "い", count: field.maxLength)
        let normalized = field.normalized(spaced)
        #expect(normalized.count == field.maxLength)
        #expect(normalized.hasPrefix("あ あ あ あ あ い"))
        #expect(field.normalized(" 　ミナト\n くん ") == "ミナト くん")
        // 上限で切った末尾が空白なら落とす
        let endsWithSpace = String(repeating: "あ", count: field.maxLength - 1) + " い"
        #expect(field.normalized(endsWithSpace) == String(repeating: "あ", count: field.maxLength - 1))
    }

    @Test("入力中の値は上限で切るだけで、空白は潰さない")
    func limitedKeepsWhitespace() {
        #expect(InputField.oshiName.limited("ミナト ") == "ミナト ")
        #expect(InputField.oshiName.limited(String(repeating: Self.family, count: 21)) == String(repeating: Self.family, count: 20))
    }

    @Test("文字数は空白を潰した後の見た目の文字数で数え、上限を超えたかを判定する", arguments: InputField.allCases)
    func lengthAndLimit(field: InputField) {
        let atLimit = String(repeating: Self.family, count: field.maxLength)
        #expect(field.length(of: "") == 0)
        #expect(field.length(of: "  ミ   ナト  ") == 4)
        #expect(field.length(of: atLimit) == field.maxLength)
        #expect(!field.exceedsLimit(atLimit))
        #expect(!field.exceedsLimit(atLimit + "  "))
        #expect(field.exceedsLimit(atLimit + "あ"))
    }

    @Test("必須はタイトルと推しの名前。空白だけは空とみなす")
    func required() {
        #expect(InputField.eventTitle.isRequired)
        #expect(InputField.oshiName.isRequired)
        #expect(!InputField.eventVenue.isRequired)

        #expect(!InputField.eventTitle.isValid(""))
        #expect(!InputField.eventTitle.isValid(" 　\n"))
        #expect(InputField.eventTitle.isValid(" ライブ "))
        #expect(!InputField.oshiName.isValid("　"))
        #expect(InputField.eventVenue.isValid(""))
    }
}
