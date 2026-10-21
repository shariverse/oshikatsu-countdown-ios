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

    /// 模様 1 つ。`position` はタイルの中の中心、`size` は記号の文字の大きさ。
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
                    // 記号はタイルをくり返す前に 1 回だけ解決する。長いほうの辺を大きさに合わせ、縦横の比を保つ
                    let images = Self.marks.map { mark in
                        var image = context.resolve(Image(systemName: mark.symbol))
                        image.shading = .color(color)
                        return (image, fittedSize(image.size, longerSide: mark.size))
                    }
                    let tile = Self.tileSize
                    var origin = CGPoint.zero
                    while origin.y < size.height {
                        origin.x = 0
                        while origin.x < size.width {
                            for (mark, (image, imageSize)) in zip(Self.marks, images) {
                                let center = CGPoint(x: origin.x + mark.position.x, y: origin.y + mark.position.y)
                                context.draw(image, in: CGRect(centeredAt: center, size: imageSize))
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
            // 長いほうの辺を大きさに合わせ、縦横の比を保つ
            let heartFrame = fittedSize(heart.size, longerSide: heartSize)
            var row = 0
            var y = spacing / 2
            while y - heartSize < size.height {
                var x = row.isMultiple(of: 2) ? spacing / 2 : spacing
                while x - heartSize < size.width {
                    context.draw(heart, in: CGRect(centeredAt: CGPoint(x: x, y: y), size: heartFrame))
                    x += spacing
                }
                y += spacing
                row += 1
            }
        }
    }
}

/// `size` の縦横の比のまま、長いほうの辺を `longerSide` にした大きさ。
private func fittedSize(_ size: CGSize, longerSide: CGFloat) -> CGSize {
    let longest = max(size.width, size.height)
    guard longest > 0 else {
        return CGSize(width: longerSide, height: longerSide)
    }
    let scale = longerSide / longest
    return CGSize(width: size.width * scale, height: size.height * scale)
}

private extension CGRect {
    /// `center` を中心にした `size` の矩形。
    init(centeredAt center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
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
