//
//  ThemeRowBackground.swift
//  OshiCon
//

import SwiftUI

extension View {
    /// Form・List の行の地を、テーマのカードの地（`surface`）にする。Section か行に付ける。
    /// システムの既定の地（ダークでは灰色）のままだと、テーマの画面の地・推しの一覧の行と色味がずれるため。
    func themeRowBackground() -> some View {
        modifier(ThemeRowBackgroundModifier())
    }
}

private struct ThemeRowBackgroundModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content.listRowBackground(theme.palette.surface.color)
    }
}
