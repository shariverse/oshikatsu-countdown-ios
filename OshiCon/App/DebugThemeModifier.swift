//
//  DebugThemeModifier.swift
//  OshiCon
//

import SwiftUI
import WidgetKit

/// 設定の「デバッグ」で選んだテーマをアプリ全体に当て、ウィジェットにも渡す（`DebugTheme`。確認用のブランチだけ）。
struct DebugThemeModifier: ViewModifier {
    /// DEBUG の起動引数 `-previewTheme` のテーマ。あれば設定より優先する（見本の撮影と UI テスト）。
    let override: AppTheme?

    @AppStorage(DebugTheme.storageKey) private var themeID = AppTheme.standard.id

    func body(content: Content) -> some View {
        content
            .environment(\.appTheme, override ?? DebugTheme.theme(id: themeID))
            .onChange(of: themeID, initial: true) {
                DebugTheme.write(id: themeID)
                WidgetCenter.shared.reloadAllTimelines()
            }
    }
}

extension View {
    /// 設定の「デバッグ」で選んだテーマを当てる。`override` があればそれを当てる。
    func debugTheme(override: AppTheme?) -> some View {
        modifier(DebugThemeModifier(override: override))
    }
}
