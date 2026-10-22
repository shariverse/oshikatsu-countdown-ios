//
//  YumekawaPastelPreviews.swift
//  OshiCon
//

import SwiftUI

// テーマ案 1「ゆめかわパステル」の見本（`AppTheme.yumekawaPastel`）。採用しなかった案（出荷するテーマは地雷系・ゴシック）。

#Preview("ゆめかわパステル・ホーム・ライト") {
    ThemePreviewCanvas(.yumekawaPastel, .home, .light)
}

#Preview("ゆめかわパステル・ホーム・ダーク") {
    ThemePreviewCanvas(.yumekawaPastel, .home, .dark)
}

#Preview("ゆめかわパステル・予定の詳細・ライト") {
    ThemePreviewCanvas(.yumekawaPastel, .eventDetail, .light)
}

#Preview("ゆめかわパステル・予定の詳細・ダーク") {
    ThemePreviewCanvas(.yumekawaPastel, .eventDetail, .dark)
}

#Preview("ゆめかわパステル・予定の追加・ライト") {
    ThemePreviewCanvas(.yumekawaPastel, .eventEditor, .light)
}

#Preview("ゆめかわパステル・予定の追加・ダーク") {
    ThemePreviewCanvas(.yumekawaPastel, .eventEditor, .dark)
}

#Preview("ゆめかわパステル・ウィジェット・ライト") {
    ThemePreviewCanvas(.yumekawaPastel, .widgets, .light)
}

#Preview("ゆめかわパステル・ウィジェット・ダーク") {
    ThemePreviewCanvas(.yumekawaPastel, .widgets, .dark)
}

#Preview("ゆめかわパステル・ホーム・大きな文字") {
    ThemePreviewCanvas(.yumekawaPastel, .home, .light)
        .dynamicTypeSize(.accessibility3)
}

#Preview("ゆめかわパステル・ホーム・横向き", traits: .landscapeLeft) {
    ThemePreviewCanvas(.yumekawaPastel, .home, .dark)
}
