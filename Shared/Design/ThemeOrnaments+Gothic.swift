//
//  ThemeOrnaments+Gothic.swift
//  OshiCon
//

import SwiftUI

// 十字とハートの装飾（地雷系・ゴシックなど）。画像の素材を使わず、十字は `Path`、ハートは SF Symbols で `Canvas` に描く。
// 置き方は `ThemeDecorations.swift` の差し込み口が決める（読み上げから外し、押せる範囲にしない）。

/// 十字の形。縦の棒を長く、横の棒を上から 3 分の 1 の高さに置く。`rect` に収め、棒の太さは幅の 4 分の 1。
enum GothicCross {
    static func path(in rect: CGRect) -> Path {
        let bar = rect.width / 4
        var path = Path()
        path.addRect(CGRect(x: rect.midX - bar / 2, y: rect.minY, width: bar, height: rect.height))
        path.addRect(CGRect(x: rect.minX, y: rect.minY + rect.height / 3 - bar / 2, width: rect.width, height: bar))
        return path
    }

    /// 縦横の比が `size` の記号を、高さ `height` で `center` に置く枠（ハートを引き伸ばさずに描く）。
    static func rect(fitting size: CGSize, height: CGFloat, center: CGPoint) -> CGRect {
        let width = size.height > 0 ? height * size.width / size.height : height
        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }
}

/// 地の色に、十字とハートを小さく散らした画面の地。
/// 模様は一定の大きさのタイルをくり返すので、iPad の広い画面でも密度は変わらない。
struct CrossesAndHeartsBackground: View {
    let ground: AdaptiveColor
    let ornament: AdaptiveColor

    /// 模様 1 つ。`position` はタイルの中の中心、`size` は高さ。
    private struct Mark {
        let isCross: Bool
        let position: CGPoint
        let size: CGFloat
    }

    private static let tileSize = CGSize(width: 180, height: 220)

    private static let marks: [Mark] = [
        Mark(isCross: true, position: CGPoint(x: 28, y: 34), size: 16),
        Mark(isCross: false, position: CGPoint(x: 132, y: 60), size: 10),
        Mark(isCross: true, position: CGPoint(x: 86, y: 128), size: 10),
        Mark(isCross: false, position: CGPoint(x: 160, y: 172), size: 12),
        Mark(isCross: true, position: CGPoint(x: 40, y: 196), size: 12)
    ]

    var body: some View {
        ground.color
            .overlay {
                Canvas { context, size in
                    let color = ornament.color.opacity(AppTheme.ScreenBackground.markOpacity)
                    var heart = context.resolve(Image(systemName: "heart.fill"))
                    heart.shading = .color(color)
                    let tile = Self.tileSize
                    var origin = CGPoint.zero
                    while origin.y < size.height {
                        origin.x = 0
                        while origin.x < size.width {
                            for mark in Self.marks {
                                let center = CGPoint(x: origin.x + mark.position.x, y: origin.y + mark.position.y)
                                if mark.isCross {
                                    let width = mark.size * 0.7
                                    let rect = CGRect(
                                        x: center.x - width / 2,
                                        y: center.y - mark.size / 2,
                                        width: width,
                                        height: mark.size
                                    )
                                    context.fill(GothicCross.path(in: rect), with: .color(color))
                                } else {
                                    context.draw(heart, in: GothicCross.rect(fitting: heart.size, height: mark.size, center: center))
                                }
                            }
                            origin.x += tile.width
                        }
                        origin.y += tile.height
                    }
                }
            }
    }
}

/// カードの内側に沿う 2 本の線。外は 1.5pt、内は 4pt 内側に 1pt で薄く引く（文字の余白の中に収まる）。
struct DoubleLineBorder<CardShape: InsettableShape>: View {
    let shape: CardShape
    let color: AdaptiveColor

    var body: some View {
        ZStack {
            shape.strokeBorder(color.color, lineWidth: 1.5)
            shape.inset(by: 4).strokeBorder(color.color.opacity(0.5), lineWidth: 1)
        }
    }
}

/// 写真が無いときに写真の場所を埋める、推し色を黒に寄せた地に白い十字とハートを互い違いに散らした模様。
struct CrossPatternBackground: View {
    /// 地の色で推し色を黒に寄せる割合。
    static let groundDarkenFraction = 0.3
    /// 十字とハートの不透明度。
    static let markOpacity = 0.2

    let color: OshiColor
    /// 模様の間隔。1 段ごとに半分ずらす。
    var spacing: CGFloat = 48

    var body: some View {
        Canvas { context, size in
            let ground = color.rgb.mixed(with: .black, fraction: Self.groundDarkenFraction).color
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(ground))
            let mark = Color.white.opacity(Self.markOpacity)
            var heart = context.resolve(Image(systemName: "heart.fill"))
            heart.shading = .color(mark)
            var row = 0
            var y = spacing / 2
            while y - spacing < size.height {
                var column = 0
                var x = row.isMultiple(of: 2) ? spacing / 2 : spacing
                while x - spacing < size.width {
                    if (row + column).isMultiple(of: 2) {
                        context.fill(GothicCross.path(in: CGRect(x: x - 5, y: y - 8, width: 10, height: 16)), with: .color(mark))
                    } else {
                        context.draw(heart, in: GothicCross.rect(fitting: heart.size, height: 12, center: CGPoint(x: x, y: y)))
                    }
                    x += spacing
                    column += 1
                }
                y += spacing
                row += 1
            }
        }
    }
}

#Preview("十字とハートの地") {
    CrossesAndHeartsBackground(
        ground: AdaptiveColor(light: 0xFFF0F5, dark: 0x120D12),
        ornament: AdaptiveColor(light: 0xF2B6CF, dark: 0x4A2A3C)
    )
    .ignoresSafeArea()
}

#Preview("二重の線") {
    RoundedRectangle(cornerRadius: 16)
        .fill(.pink)
        .overlay {
            DoubleLineBorder(shape: RoundedRectangle(cornerRadius: 16), color: AdaptiveColor(light: 0x1A0F16, dark: 0xFF7EB3))
        }
        .frame(width: 240, height: 140)
}

#Preview("十字とハートの模様") {
    CrossPatternBackground(color: .pink)
        .frame(width: 200, height: 200)
}
