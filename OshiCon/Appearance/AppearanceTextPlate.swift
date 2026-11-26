//
//  AppearanceTextPlate.swift
//  OshiCon
//

import SwiftUI

extension EnvironmentValues {
    /// 地に着せ替えの写真（背景の写真か、推しの丸い写真の飾り。`AppearanceRendering.drawsPhotosOnGround`）を描いているか。
    /// true のとき、地の上に直接描く文字の後ろに板を敷く（`appearanceTextPlate()`）。
    @Entry var isOverAppearancePhoto = false
}

/// 着せ替えの写真（背景の写真・推しの丸い写真の飾り）の上で、地の上に直接描く文字（見出し・案内）の後ろに敷く板。
///
/// 背景の写真は推しが見えるよう幕を薄くでき（`AppearanceBackgroundStyle`）、飾りは濃くできる（`OshiPhotoDecorationStyle`）ので、写真の色によっては地の上の文字が読めなくなる。
/// そこで着せ替えの写真を描いているときだけ、文字の後ろをカードの地の色（`surface`）で塗る。
/// 本文の色（`onSurface`・`onSurfaceVariant`）はカードの地の上で 4.5:1 以上なので（`PaletteContrastTests`）、写真の色や濃さによらず読める。
/// 標準の見た目のときは板を敷かない（地の模様の上で 4.5:1 以上を保っている）。
nonisolated enum AppearanceTextPlate {
    /// 板の色。カードの地の色。
    static func color(in theme: AppTheme) -> AdaptiveColor {
        theme.palette.surface
    }
}

extension View {
    /// 着せ替えの写真を描いているとき（`isOverAppearancePhoto`）だけ、見出し・案内の文字の後ろに小さな板を敷く。
    func appearanceTextPlate() -> some View {
        modifier(AppearanceTextPlateModifier(style: .label))
    }

    /// 着せ替えの写真を描いているとき（`isOverAppearancePhoto`）だけ、中身の高さに縮めてカードの形の板を敷く。
    /// 画面いっぱいに広がる空の案内（`ContentUnavailableView`）に使う。
    func appearanceBlockPlate() -> some View {
        modifier(AppearanceTextPlateModifier(style: .block))
    }
}

private struct AppearanceTextPlateModifier: ViewModifier {
    enum Style {
        /// 見出し・1 行の案内。文字のまわりだけ。
        case label
        /// 空の案内。中身の高さに縮め、カードの形にする。
        case block
    }

    let style: Style

    @Environment(\.isOverAppearancePhoto) private var isOverAppearancePhoto
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        if isOverAppearancePhoto {
            switch style {
            case .label:
                content
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppearanceTextPlate.color(in: theme).color, in: RoundedRectangle(cornerRadius: theme.shape.tag))
            case .block:
                content
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 8)
                    .background(AppearanceTextPlate.color(in: theme).color, in: RoundedRectangle(cornerRadius: theme.shape.section))
                    .themeCardBorder(RoundedRectangle(cornerRadius: theme.shape.section))
                    .padding()
                    // 板の外は今までどおり画面いっぱいに広げる（縮めると、地が板の高さにしか敷かれない）
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            content
        }
    }
}
