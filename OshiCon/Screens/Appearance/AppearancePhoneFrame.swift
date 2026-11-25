//
//  AppearancePhoneFrame.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの画面の見本（ホーム・予定の詳細）の枠。中身を iPhone の縦の画面の大きさ（`AppearancePreview.canvasSize`）で組み、幅 `width` に縮めて見せる。
///
/// - 中の文字の大きさは、画面のダイナミックタイプによらず標準の大きさにする（縮めた絵なので、大きくすると崩れる）
/// - 縮めて見せるので、中の写真は見せる大きさに合わせて読む（`displayScale` を縮めた倍率にする）
/// - 端末の角のような丸みを付け、アクセントの色で縁取る
struct AppearancePhoneFrame<Content: View>: View {
    /// 見本を見せる幅（pt）。高さは縦横の比（`AppearancePreview.canvasSize`）から決まる。
    let width: CGFloat
    @ViewBuilder var content: () -> Content

    @Environment(\.appTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    /// 見本の角の丸み（pt。縮める前の大きさで数える）。見本を小さく見せても、端末の角のような形を保つ。
    private let canvasCornerRadius: CGFloat = 52

    var body: some View {
        let canvas = AppearancePreview.canvasSize
        let factor = AppearancePreview.displayScaleFactor(width: width)
        let size = CGSize(width: canvas.width * factor, height: canvas.height * factor)
        let shape = RoundedRectangle(cornerRadius: canvasCornerRadius * factor)
        content()
            .frame(width: canvas.width, height: canvas.height, alignment: .top)
            .clipped()
            .dynamicTypeSize(.large)
            .environment(\.horizontalSizeClass, .compact)
            .environment(\.verticalSizeClass, .regular)
            .environment(\.displayScale, displayScale * factor)
            .scaleEffect(factor, anchor: .topLeading)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(theme.palette.brand.color, lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
    }
}
