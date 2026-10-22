//
//  IdolPenlightPreviews.swift
//  OshiCon
//

import SwiftUI

// テーマ案 5「アイドル・ペンライト」の見本（`AppTheme.idolPenlight`）。採用しなかった案（出荷するテーマは地雷系・ゴシック）。

#Preview("アイドル・ペンライト・ホーム・ライト") {
    ThemePreviewCanvas(.idolPenlight, .home, .light)
}

#Preview("アイドル・ペンライト・ホーム・ダーク") {
    ThemePreviewCanvas(.idolPenlight, .home, .dark)
}

#Preview("アイドル・ペンライト・予定の詳細・ライト") {
    ThemePreviewCanvas(.idolPenlight, .eventDetail, .light)
}

#Preview("アイドル・ペンライト・予定の詳細・ダーク") {
    ThemePreviewCanvas(.idolPenlight, .eventDetail, .dark)
}

#Preview("アイドル・ペンライト・予定の追加・ライト") {
    ThemePreviewCanvas(.idolPenlight, .eventEditor, .light)
}

#Preview("アイドル・ペンライト・予定の追加・ダーク") {
    ThemePreviewCanvas(.idolPenlight, .eventEditor, .dark)
}

#Preview("アイドル・ペンライト・ウィジェット・ライト") {
    ThemePreviewCanvas(.idolPenlight, .widgets, .light)
}

#Preview("アイドル・ペンライト・ウィジェット・ダーク") {
    ThemePreviewCanvas(.idolPenlight, .widgets, .dark)
}

#Preview("アイドル・ペンライト・ホーム・大きな文字") {
    ThemePreviewCanvas(.idolPenlight, .home, .dark)
        .dynamicTypeSize(.accessibility3)
}

#Preview("アイドル・ペンライト・ホーム・横向き", traits: .landscapeLeft) {
    ThemePreviewCanvas(.idolPenlight, .home, .dark)
}
