//
//  ThemeOrnaments+Minimal.swift
//  OshiCon
//

import SwiftUI

// 細い線と、色の濃さだけで描く控えめな装飾（韓国風ミニマルなど）。置き方は `ThemeDecorations.swift` の差し込み口が決める。

/// 画面の 1 画素の太さの横線。残りの幅いっぱいに伸びる。
struct ThinRule: View {
    let color: AdaptiveColor

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(color.color)
            .frame(height: 1 / displayScale)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

/// 写真が無いときに写真の場所を埋める、推し色の地を上から下へわずかに濃くした模様。
struct TonalBackground: View {
    /// 上の端で白に、下の端で黒に寄せる割合。
    static let toneFraction = 0.12

    let color: OshiColor

    var body: some View {
        LinearGradient(
            colors: [
                color.rgb.mixed(with: .white, fraction: Self.toneFraction).color,
                color.rgb.mixed(with: .black, fraction: Self.toneFraction).color
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("細い線") {
    ThinRule(color: AdaptiveColor(light: 0xD8CEC5, dark: 0x4A443F))
        .padding()
}

#Preview("推し色の濃淡") {
    TonalBackground(color: .navy)
        .frame(width: 200, height: 200)
}
