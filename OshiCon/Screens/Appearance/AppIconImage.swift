//
//  AppIconImage.swift
//  OshiCon
//

import SwiftUI

/// アプリアイコンの見本。推し色の地に白いハート（ダークの外観は暗い地に淡い推し色のハート。`AppIconPalette`）。
///
/// アセットカタログのアイコン（Icon Composer の `.icon`）はアプリから画像として読めないので、同じ図柄を SwiftUI の図形で描く。
/// ハートの形と大きさは、アイコンの図柄（`AppIcon.icon/Assets/heart.svg`。1024 四方の中）と同じ。
struct AppIconImage: View {
    let color: OshiColor
    let isDark: Bool
    /// 一辺（pt）。
    let side: CGFloat

    /// 角の丸みの一辺に対する割合（ホーム画面のアイコンの形に近づける）。
    static let cornerRadiusFraction: CGFloat = 0.225

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: side * Self.cornerRadiusFraction, style: .continuous)
        ZStack {
            AppIconPalette.ground(of: color, isDark: isDark).color
            AppIconHeart()
                .fill(AppIconPalette.heart(of: color, isDark: isDark).color)
                // アイコンの図柄の影（icon.json の shadow）に近づける
                .shadow(color: .black.opacity(0.18), radius: side * 0.02, y: side * 0.012)
        }
        .frame(width: side, height: side)
        .clipShape(shape)
        .overlay {
            // ダークの暗い地が、暗い背景に溶けないよう細い線で縁取る
            if isDark {
                shape.strokeBorder(.white.opacity(0.16), lineWidth: max(side / 120, 0.5))
            }
        }
        .accessibilityHidden(true)
    }
}

/// アイコンの図柄のハート（`heart.svg` の形。1024 四方の中で x 212〜812、y 226〜806）。
nonisolated struct AppIconHeart: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 1_024
        let origin = CGPoint(x: rect.midX - 512 * scale, y: rect.midY - 512 * scale)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
        }
        var path = Path()
        path.move(to: point(512, 806))
        path.addCurve(to: point(212, 412), control1: point(470, 776), control2: point(212, 604))
        path.addCurve(to: point(392, 226), control1: point(212, 302), control2: point(294, 226))
        path.addCurve(to: point(512, 296), control1: point(448, 226), control2: point(492, 254))
        path.addCurve(to: point(632, 226), control1: point(532, 254), control2: point(576, 226))
        path.addCurve(to: point(812, 412), control1: point(730, 226), control2: point(812, 302))
        path.addCurve(to: point(512, 806), control1: point(812, 604), control2: point(554, 776))
        path.closeSubpath()
        return path
    }
}

#Preview("12 色") {
    VStack(spacing: 16) {
        ForEach([false, true], id: \.self) { isDark in
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(OshiColor.allCases, id: \.self) { color in
                    AppIconImage(color: color, isDark: isDark, side: 52)
                }
            }
            .padding()
            .background(isDark ? Color.black : Color(white: 0.95))
        }
    }
}
