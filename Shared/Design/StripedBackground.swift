//
//  StripedBackground.swift
//  OshiCon
//

import SwiftUI

/// 写真が無いときに写真の場所を埋める、推し色の斜めの縞（135°）。
struct StripedBackground: View {
    /// 縞の濃いほうの色。推し色を黒に寄せる割合。
    static let deepStripeFraction = 0.2

    let color: OshiColor
    /// 縞 1 本の幅。
    var stripeWidth: CGFloat = 22

    var body: some View {
        Canvas { context, size in
            let base = color.rgb
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(base.color))
            let deep = base.mixed(with: .black, fraction: Self.deepStripeFraction).color
            // 左上から右下へ色が移る縞（右上から左下へ走る線）。横の周期は 1 本の幅 × 2 × √2（縞に垂直な幅が stripeWidth になる）
            let period = stripeWidth * 2 * 2.squareRoot()
            let band = period / 2
            var offset: CGFloat = 0
            while offset < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: offset + band, y: 0))
                path.addLine(to: CGPoint(x: offset + band * 2, y: 0))
                path.addLine(to: CGPoint(x: offset + band * 2 - size.height, y: size.height))
                path.addLine(to: CGPoint(x: offset + band - size.height, y: size.height))
                path.closeSubpath()
                context.fill(path, with: .color(deep))
                offset += period
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    StripedBackground(color: .pink)
        .frame(width: 200, height: 200)
}
