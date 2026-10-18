//
//  InputLengthFooter.swift
//  OshiCon
//

import SwiftUI

/// 入力欄の下に出す文字数（`n / 上限`）。上限を超えたら「N 文字までです」と赤く出す。
/// 打っている途中では切らないので（日本語の変換中に切らないため）、超えたことをここで知らせる。
struct InputLengthFooter: View {
    let field: InputField
    let text: String

    private var length: Int {
        field.length(of: text)
    }

    private var exceedsLimit: Bool {
        field.exceedsLimit(text)
    }

    var body: some View {
        // 大きな文字サイズで 1 行に収まらなければ縦に並べる
        ViewThatFits(in: .horizontal) {
            HStack {
                limitMessage
                Spacer()
                count
            }
            VStack(alignment: .trailing, spacing: 2) {
                limitMessage
                    .frame(maxWidth: .infinity, alignment: .leading)
                count
            }
        }
        .foregroundStyle(exceedsLimit ? AppPalette.destructive.color : AppPalette.onSurfaceVariant.color)
    }

    @ViewBuilder private var limitMessage: some View {
        if exceedsLimit {
            Text("\(field.maxLength) 文字までです")
        }
    }

    private var count: some View {
        Text(verbatim: "\(length) / \(field.maxLength)")
            .monospacedDigit()
            .accessibilityLabel("\(field.maxLength) 文字中 \(length) 文字")
    }
}

#Preview {
    Form {
        Section {
            Text("ミナト")
        } footer: {
            InputLengthFooter(field: .oshiName, text: "ミナト")
        }
        Section {
            Text(String(repeating: "あ", count: 21))
        } footer: {
            InputLengthFooter(field: .oshiName, text: String(repeating: "あ", count: 21))
        }
    }
}
