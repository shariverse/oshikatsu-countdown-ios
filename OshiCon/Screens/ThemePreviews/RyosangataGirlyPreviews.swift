//
//  RyosangataGirlyPreviews.swift
//  OshiCon
//

import SwiftUI

// テーマ案 2「量産型ガーリー」の見本（`AppTheme.ryosangataGirly`）。出荷するアプリは既定のテーマのまま。

#Preview("量産型ガーリー・ホーム・ライト") {
    ThemePreviewCanvas(.ryosangataGirly, .home, .light)
}

#Preview("量産型ガーリー・ホーム・ダーク") {
    ThemePreviewCanvas(.ryosangataGirly, .home, .dark)
}

#Preview("量産型ガーリー・予定の詳細・ライト") {
    ThemePreviewCanvas(.ryosangataGirly, .eventDetail, .light)
}

#Preview("量産型ガーリー・予定の詳細・ダーク") {
    ThemePreviewCanvas(.ryosangataGirly, .eventDetail, .dark)
}

#Preview("量産型ガーリー・予定の追加・ライト") {
    ThemePreviewCanvas(.ryosangataGirly, .eventEditor, .light)
}

#Preview("量産型ガーリー・予定の追加・ダーク") {
    ThemePreviewCanvas(.ryosangataGirly, .eventEditor, .dark)
}

#Preview("量産型ガーリー・ウィジェット・ライト") {
    ThemePreviewCanvas(.ryosangataGirly, .widgets, .light)
}

#Preview("量産型ガーリー・ウィジェット・ダーク") {
    ThemePreviewCanvas(.ryosangataGirly, .widgets, .dark)
}

#Preview("量産型ガーリー・ホーム・大きな文字") {
    ThemePreviewCanvas(.ryosangataGirly, .home, .light)
        .dynamicTypeSize(.accessibility3)
}

#Preview("量産型ガーリー・ホーム・横向き", traits: .landscapeLeft) {
    ThemePreviewCanvas(.ryosangataGirly, .home, .dark)
}
