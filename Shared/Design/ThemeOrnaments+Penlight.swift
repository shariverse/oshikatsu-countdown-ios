//
//  ThemeOrnaments+Penlight.swift
//  OshiCon
//

import SwiftUI

// テーマ案 5「アイドル・ペンライト」の装飾の模様。画像の素材を使わず、グラデーションと図形で描く。
// 置き方は `ThemeDecorations.swift` の差し込み口が決める（読み上げから外し、押せる範囲にしない）。

/// 上から下へ色を移し、上からライブ会場の照明の光の筋を差す画面の地。光の筋は上の端から下へ薄れる。
struct StageBackground: View {
    let gradient: [AdaptiveColor]
    let beam: AdaptiveColor

    /// 光の筋 1 本。`origin` は上の端の位置（幅に対する割合）、`angle` は真下からの傾き、`spread` は下の端での幅（画面の幅に対する割合）。
    private struct Beam {
        let origin: CGFloat
        let angle: Angle
        let spread: CGFloat
    }

    private static let beams: [Beam] = [
        Beam(origin: 0.18, angle: .degrees(18), spread: 0.22),
        Beam(origin: 0.5, angle: .degrees(-8), spread: 0.18),
        Beam(origin: 0.82, angle: .degrees(-22), spread: 0.24)
    ]

    var body: some View {
        LinearGradient(colors: gradient.map(\.color), startPoint: .top, endPoint: .bottom)
            .overlay {
                Canvas { context, size in
                    // 光は画面の上の 7 割ほどに差し、下は地の色だけにする
                    let length = size.height * 0.7
                    let shading = GraphicsContext.Shading.linearGradient(
                        Gradient(colors: [
                            beam.color.opacity(AppTheme.ScreenBackground.beamOpacity),
                            beam.color.opacity(0)
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: length)
                    )
                    for item in Self.beams {
                        let top = CGPoint(x: size.width * item.origin, y: 0)
                        let shift = tan(item.angle.radians) * length
                        let half = size.width * item.spread / 2
                        var path = Path()
                        path.move(to: CGPoint(x: top.x - 4, y: 0))
                        path.addLine(to: CGPoint(x: top.x + 4, y: 0))
                        path.addLine(to: CGPoint(x: top.x + shift + half, y: length))
                        path.addLine(to: CGPoint(x: top.x + shift - half, y: length))
                        path.closeSubpath()
                        context.fill(path, with: shading)
                    }
                }
            }
    }
}

/// ネオン管のような縁。カードの縁に細い線を引き、同じ色の光を線のまわりに広げる。
/// 光の広がり（8pt）はカードの余白（先頭のカード 20pt・行 12pt）より狭く、文字には届かない。
struct NeonBorder<CardShape: InsettableShape>: View {
    /// 線の太さ。
    static var lineWidth: CGFloat {
        1.5
    }

    let shape: CardShape
    let color: AdaptiveColor

    var body: some View {
        shape.strokeBorder(color.color, lineWidth: Self.lineWidth)
            .shadow(color: color.color.opacity(0.6), radius: 8)
    }
}

/// 写真が無いときに写真の場所を埋める、推し色の地に、ぼけたペンライトの光の玉を散らした模様。
/// 光の玉は推し色を白に寄せた色で、推し色を置き換えない。一定の大きさのタイルをくり返す。
struct PenlightBokehBackground: View {
    let color: OshiColor

    /// 光の玉 1 つ。`position` はタイルの中の中心、`diameter` は直径、`opacity` は中心の不透明度。
    private struct Bokeh {
        let position: CGPoint
        let diameter: CGFloat
        let opacity: Double
    }

    private static let tileSize = CGSize(width: 180, height: 150)

    private static let bokehs: [Bokeh] = [
        Bokeh(position: CGPoint(x: 30, y: 36), diameter: 46, opacity: 0.32),
        Bokeh(position: CGPoint(x: 112, y: 22), diameter: 24, opacity: 0.4),
        Bokeh(position: CGPoint(x: 150, y: 96), diameter: 56, opacity: 0.24),
        Bokeh(position: CGPoint(x: 72, y: 112), diameter: 30, opacity: 0.36),
        Bokeh(position: CGPoint(x: 8, y: 132), diameter: 18, opacity: 0.44)
    ]

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color.fill))
            let light = color.rgb.mixed(with: .white, fraction: 0.6).color
            let tile = Self.tileSize
            var origin = CGPoint.zero
            while origin.y < size.height {
                origin.x = 0
                while origin.x < size.width {
                    for bokeh in Self.bokehs {
                        let center = CGPoint(x: origin.x + bokeh.position.x, y: origin.y + bokeh.position.y)
                        let radius = bokeh.diameter / 2
                        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: bokeh.diameter, height: bokeh.diameter)
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .radialGradient(
                                Gradient(colors: [light.opacity(bokeh.opacity), light.opacity(0)]),
                                center: center,
                                startRadius: 0,
                                endRadius: radius
                            )
                        )
                    }
                    origin.x += tile.width
                }
                origin.y += tile.height
            }
        }
    }
}

#Preview("照明の地") {
    StageBackground(
        gradient: [AdaptiveColor(light: 0xFBF7FF, dark: 0x0E0B1A), AdaptiveColor(light: 0xFDF3FA, dark: 0x1A0D24)],
        beam: AdaptiveColor(light: 0xE9D5FF, dark: 0x6B4BB8)
    )
    .ignoresSafeArea()
}

#Preview("ペンライトの光の玉") {
    PenlightBokehBackground(color: .blue)
        .frame(width: 240, height: 200)
}
