//
//  JiraiGothicPreviews.swift
//  OshiCon
//

import SwiftUI

// テーマ案 4「地雷系・ゴシック」の見本（`AppTheme.jiraiGothic`）。出荷するアプリは既定のテーマのまま。

#Preview("地雷系・ゴシック・ホーム・ライト") {
    ThemePreviewCanvas(.jiraiGothic, .home, .light)
}

#Preview("地雷系・ゴシック・ホーム・ダーク") {
    ThemePreviewCanvas(.jiraiGothic, .home, .dark)
}

#Preview("地雷系・ゴシック・予定の詳細・ライト") {
    ThemePreviewCanvas(.jiraiGothic, .eventDetail, .light)
}

#Preview("地雷系・ゴシック・予定の詳細・ダーク") {
    ThemePreviewCanvas(.jiraiGothic, .eventDetail, .dark)
}

#Preview("地雷系・ゴシック・予定の追加・ライト") {
    ThemePreviewCanvas(.jiraiGothic, .eventEditor, .light)
}

#Preview("地雷系・ゴシック・予定の追加・ダーク") {
    ThemePreviewCanvas(.jiraiGothic, .eventEditor, .dark)
}

#Preview("地雷系・ゴシック・ウィジェット・ライト") {
    ThemePreviewCanvas(.jiraiGothic, .widgets, .light)
}

#Preview("地雷系・ゴシック・ウィジェット・ダーク") {
    ThemePreviewCanvas(.jiraiGothic, .widgets, .dark)
}

#Preview("地雷系・ゴシック・ホーム・大きな文字") {
    ThemePreviewCanvas(.jiraiGothic, .home, .light)
        .dynamicTypeSize(.accessibility3)
}

#Preview("地雷系・ゴシック・ホーム・横向き", traits: .landscapeLeft) {
    ThemePreviewCanvas(.jiraiGothic, .home, .dark)
}
