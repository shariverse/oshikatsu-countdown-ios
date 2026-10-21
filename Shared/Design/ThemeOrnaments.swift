//
//  ThemeOrnaments.swift
//  OshiCon
//

import SwiftUI

// テーマの装飾の模様。画像の素材を使わず、SwiftUI のグラデーションと SF Symbols を `Canvas` で描く。
// 置き方は `ThemeDecorations.swift` の差し込み口が決める（読み上げから外し、押せる範囲にしない）。

/// 淡いグラデーションに、星とハートを小さく散らした画面の地。
/// 模様は一定の大きさのタイルをくり返すので、iPad の広い画面でも密度は変わらない。
struct SparkleBackground: View {
    let gradient: [AdaptiveColor]
    let ornament: AdaptiveColor

    /// 模様 1 つ。`position` はタイルの中の中心、`size` は一辺の大きさ。
    private struct Mark {
        let symbol: String
        let position: CGPoint
        let size: CGFloat
    }

    private static let tileSize = CGSize(width: 200, height: 240)

    private static let marks: [Mark] = [
        Mark(symbol: "sparkle", position: CGPoint(x: 24, y: 30), size: 14),
        Mark(symbol: "heart.fill", position: CGPoint(x: 150, y: 52), size: 10),
        Mark(symbol: "star.fill", position: CGPoint(x: 92, y: 110), size: 8),
        Mark(symbol: "sparkle", position: CGPoint(x: 176, y: 168), size: 10),
        Mark(symbol: "heart.fill", position: CGPoint(x: 46, y: 196), size: 12),
        Mark(symbol: "star.fill", position: CGPoint(x: 120, y: 222), size: 6)
    ]

    var body: some View {
        LinearGradient(colors: gradient.map(\.color), startPoint: .top, endPoint: .bottom)
            .overlay {
                Canvas { context, size in
                    let color = ornament.color.opacity(AppTheme.ScreenBackground.ornamentOpacity)
                    let tile = Self.tileSize
                    var origin = CGPoint.zero
                    while origin.y < size.height {
                        origin.x = 0
                        while origin.x < size.width {
                            for mark in Self.marks {
                                var image = context.resolve(Image(systemName: mark.symbol))
                                image.shading = .color(color)
                                let center = CGPoint(x: origin.x + mark.position.x, y: origin.y + mark.position.y)
                                let rect = CGRect(
                                    x: center.x - mark.size / 2,
                                    y: center.y - mark.size / 2,
                                    width: mark.size,
                                    height: mark.size
                                )
                                context.draw(image, in: rect)
                            }
                            origin.x += tile.width
                        }
                        origin.y += tile.height
                    }
                }
            }
    }
}

/// 写真が無いときに写真の場所を埋める、推し色の地に白いハートを散らした模様。
struct HeartPatternBackground: View {
    /// ハートの不透明度。
    static let heartOpacity = 0.24

    let color: OshiColor
    /// ハートの間隔。1 段ごとに半分ずらす。
    var spacing: CGFloat = 44
    /// ハートの大きさ。
    var heartSize: CGFloat = 14

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color.fill))
            var heart = context.resolve(Image(systemName: "heart.fill"))
            heart.shading = .color(.white.opacity(Self.heartOpacity))
            var row = 0
            var y = spacing / 2
            while y - heartSize < size.height {
                var x = row.isMultiple(of: 2) ? spacing / 2 : spacing
                while x - heartSize < size.width {
                    context.draw(
                        heart,
                        in: CGRect(x: x - heartSize / 2, y: y - heartSize / 2, width: heartSize, height: heartSize)
                    )
                    x += spacing
                }
                y += spacing
                row += 1
            }
        }
    }
}

#Preview("星とハートの地") {
    SparkleBackground(
        gradient: [AdaptiveColor(light: 0xFFF5FA, dark: 0x1C1726), AdaptiveColor(light: 0xF1F8FF, dark: 0x16192C)],
        ornament: AdaptiveColor(light: 0xF2A6CB, dark: 0x8A6AAE)
    )
    .ignoresSafeArea()
}

#Preview("ハートの模様") {
    HeartPatternBackground(color: .lavender)
        .frame(width: 200, height: 200)
}
