//
//  EventDetailProgressBar.swift
//  OshiCon
//

import SwiftUI

/// 進み具合のバーの塗りと、先端のハートの置き方（画面から切り離してテストする）。
nonisolated enum EventDetailProgressLayout {
    /// バーの太さ。
    static let barHeight: CGFloat = 8
    /// 先端のハートの大きさ（縁取りを含む枠）。
    static let heartSize: CGFloat = 24

    /// 塗りの幅。`progress` は 0〜1 に収める。
    static func fillWidth(progress: Double, barWidth: CGFloat) -> CGFloat {
        max(barWidth, 0) * min(max(progress, 0), 1)
    }

    /// ハートの左端の位置。塗りの先端にハートの中心を合わせる。
    /// 0% と 100% では、ハートの半分がバーの端からカードの余白にはみ出す（塗りの丸い端がハートの横に残らないようにする）。
    static func heartOffset(progress: Double, barWidth: CGFloat, heartSize: CGFloat = EventDetailProgressLayout.heartSize) -> CGFloat {
        fillWidth(progress: progress, barWidth: barWidth) - heartSize / 2
    }
}

/// 進み具合のバー。溝の上に推し色の塗りを重ね、先端にハートの印（推し色）を置く。飾りなので読み上げない（読み上げは下のラベルと合わせて親が付ける）。
struct EventDetailProgressBar: View {
    /// 進み具合（0〜1）。
    let progress: Double
    /// 塗りとハートの色（推し色の文字の色）。
    let tint: Color

    @Environment(\.appTheme) private var theme

    var body: some View {
        GeometryReader { proxy in
            let barWidth = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.palette.surfaceContainerHigh.color)
                    .frame(height: EventDetailProgressLayout.barHeight)
                Capsule()
                    .fill(tint)
                    .frame(
                        width: EventDetailProgressLayout.fillWidth(progress: progress, barWidth: barWidth),
                        height: EventDetailProgressLayout.barHeight
                    )
                heart
                    .offset(x: EventDetailProgressLayout.heartOffset(progress: progress, barWidth: barWidth))
            }
            .frame(width: barWidth, height: proxy.size.height, alignment: .leading)
        }
        .frame(height: EventDetailProgressLayout.heartSize)
        .accessibilityHidden(true)
    }

    /// 先端のハート。バーと重なっても形がわかるよう、カードの地の色で縁取る。
    private var heart: some View {
        EventDetailHeartShape()
            .fill(tint)
            .overlay {
                EventDetailHeartShape()
                    .stroke(theme.palette.surface.color, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            }
            .frame(width: EventDetailProgressLayout.heartSize, height: EventDetailProgressLayout.heartSize)
    }
}

/// ハートの形。24 × 24 の枠に描いた形を、`rect` の大きさに合わせる。形は描く側のスレッドで作られるので、メインアクターに縛らない。
nonisolated private struct EventDetailHeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale)
        }
        var path = Path()
        path.move(to: point(12, 21))
        path.addCurve(to: point(2.5, 11.8), control1: point(12, 21), control2: point(4.5, 16.4))
        path.addCurve(to: point(6.6, 5), control1: point(1, 8.3), control2: point(3.2, 5))
        path.addCurve(to: point(12, 8), control1: point(8.6, 5), control2: point(10.2, 6.1))
        path.addCurve(to: point(17.4, 5), control1: point(13.8, 6.1), control2: point(15.4, 5))
        path.addCurve(to: point(21.5, 11.8), control1: point(20.8, 5), control2: point(23, 8.3))
        path.addCurve(to: point(12, 21), control1: point(19.5, 16.4), control2: point(12, 21))
        path.closeSubpath()
        return path
    }
}

#Preview("進み具合のバー") {
    VStack(spacing: 24) {
        ForEach([0, 0.04, 0.5, 0.76, 1], id: \.self) { progress in
            EventDetailProgressBar(progress: progress, tint: OshiColor.pink.text(in: .shipping).color)
        }
    }
    .padding(20)
    .background(AppTheme.shipping.palette.surface.color)
}
