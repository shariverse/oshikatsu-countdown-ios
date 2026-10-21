//
//  KoreanMinimalPreviews.swift
//  OshiCon
//

import SwiftUI

// テーマ案 3「韓国風ミニマル」の見本（`AppTheme.koreanMinimal`）。出荷するアプリは既定のテーマのまま。

#Preview("韓国風ミニマル・ホーム・ライト") {
    ThemePreviewCanvas(.koreanMinimal, .home, .light)
}

#Preview("韓国風ミニマル・ホーム・ダーク") {
    ThemePreviewCanvas(.koreanMinimal, .home, .dark)
}

#Preview("韓国風ミニマル・予定の詳細・ライト") {
    ThemePreviewCanvas(.koreanMinimal, .eventDetail, .light)
}

#Preview("韓国風ミニマル・予定の詳細・ダーク") {
    ThemePreviewCanvas(.koreanMinimal, .eventDetail, .dark)
}

#Preview("韓国風ミニマル・予定の追加・ライト") {
    ThemePreviewCanvas(.koreanMinimal, .eventEditor, .light)
}

#Preview("韓国風ミニマル・予定の追加・ダーク") {
    ThemePreviewCanvas(.koreanMinimal, .eventEditor, .dark)
}

#Preview("韓国風ミニマル・ウィジェット・ライト") {
    ThemePreviewCanvas(.koreanMinimal, .widgets, .light)
}

#Preview("韓国風ミニマル・ウィジェット・ダーク") {
    ThemePreviewCanvas(.koreanMinimal, .widgets, .dark)
}

#Preview("韓国風ミニマル・ホーム・大きな文字") {
    ThemePreviewCanvas(.koreanMinimal, .home, .light)
        .dynamicTypeSize(.accessibility3)
}

#Preview("韓国風ミニマル・ホーム・横向き", traits: .landscapeLeft) {
    ThemePreviewCanvas(.koreanMinimal, .home, .dark)
}
