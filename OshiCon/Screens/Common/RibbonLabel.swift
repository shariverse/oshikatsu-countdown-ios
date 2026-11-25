//
//  RibbonLabel.swift
//  OshiCon
//

import SwiftUI

/// リボンの札の形。右の端に、三角の切れ込みを入れる。
nonisolated struct RibbonShape: Shape {
    /// 切れ込みの深さ。
    static let notchDepth: CGFloat = 9

    func path(in rect: CGRect) -> Path {
        let depth = min(Self.notchDepth, rect.width / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - depth, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// リボンの札（ホームの見出し・推しの一覧の「1 位」）。アクセント（`brand`）の地に `onBrand` の文字を置き、右の端に切れ込みを入れる。
///
/// 自分の地を持つので、着せ替えの背景の写真・飾りの上でも読める（`onBrand` は `brand` の上で 4.5:1 以上。`PaletteContrastTests`）。
/// そのため、地の上の文字の後ろに敷く板（`appearanceTextPlate()`）は要らない。
/// 印（`systemImage`）は飾りで、読み上げない。
struct RibbonLabel: View {
    let title: Text
    /// 文字の前に置く SF Symbols の名前。
    var systemImage: String?
    var textStyle: Font.TextStyle = .subheadline

    @Environment(\.appTheme) private var theme

    var body: some View {
        // 2 行になっても印は 1 行目にそろえる
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(textStyle))
                    .imageScale(.small)
                    // 大きな文字では札の幅を削りすぎないよう、印の大きさに上限を付ける
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .accessibilityHidden(true)
            }
            title
                .font(theme.typography.text(textStyle, weight: .bold))
        }
        .foregroundStyle(theme.palette.onBrand.color)
        .padding(.leading, 12)
        // 切れ込みに文字がかからないよう、切れ込みの深さの分だけ右を空ける
        .padding(.trailing, 12 + RibbonShape.notchDepth)
        .padding(.vertical, 5)
        .background(theme.palette.brand.color, in: RibbonShape())
    }
}

extension AppTheme.HeadingOrnament {
    /// 見出しの前に置く SF Symbols の名前。飾りが無ければ nil。リボンの札（`RibbonLabel`）の中に、札の文字の色で置く。
    var symbolName: String? {
        switch self {
        case .none:
            nil
        case let .symbol(name, _):
            name
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        RibbonLabel(title: Text(verbatim: "これからの予定"), systemImage: "heart.fill")
        RibbonLabel(title: Text(verbatim: "1 位"), systemImage: "crown.fill", textStyle: .footnote)
        RibbonLabel(title: Text(verbatim: "終わった予定"))
    }
    .padding()
}
