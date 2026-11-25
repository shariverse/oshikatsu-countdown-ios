//
//  TicketShape.swift
//  OshiCon
//

import SwiftUI

/// チケットの形。角の丸い四角の左右の辺に、半円の切り欠きを入れる。切り欠きを結ぶ線がミシン目で、その下が半券。
/// カードの二重の線（`themeCardBorder(_:)`）が切り欠きに沿うよう、内側に寄せた形も作る（`InsettableShape`）。
nonisolated struct TicketShape: InsettableShape {
    /// 切り欠きの半径。
    static let notchRadius: CGFloat = 9

    /// 角の丸み。
    var cornerRadius: CGFloat
    /// 下の辺からミシン目（切り欠きの中心）までの高さ。0 以下のときは切り欠きを入れない（半券の高さをまだ測っていないとき）。
    var stubHeight: CGFloat
    /// 内側に寄せた幅。
    private var insetAmount: CGFloat = 0

    init(cornerRadius: CGFloat, stubHeight: CGFloat) {
        self.cornerRadius = cornerRadius
        self.stubHeight = stubHeight
    }

    func path(in rect: CGRect) -> Path {
        let card = Path(
            roundedRect: rect.insetBy(dx: insetAmount, dy: insetAmount),
            cornerRadius: max(cornerRadius - insetAmount, 0)
        )
        guard stubHeight > 0, stubHeight < rect.height else {
            return card
        }
        // 切り欠きは、寄せる前の辺の上に中心を置いた円。内側に寄せた形では、同じ中心のまま半径を寄せた分だけ大きくする
        let radius = Self.notchRadius + insetAmount
        let centerY = rect.maxY - stubHeight
        var notches = Path()
        for centerX in [rect.minX, rect.maxX] {
            notches.addEllipse(in: CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2))
        }
        return card.subtracting(notches)
    }

    func inset(by amount: CGFloat) -> Self {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

/// チケットのミシン目。横に引く点線で、本体と半券を分ける。飾りなので、置く側で読み上げから外す。
nonisolated struct TicketPerforation: Shape {
    /// 点線の太さ。
    static let lineWidth: CGFloat = 2
    /// 点と間の長さ。
    static let dash: [CGFloat] = [5, 4]

    func path(in rect: CGRect) -> Path {
        var line = Path()
        line.move(to: CGPoint(x: rect.minX, y: rect.midY))
        line.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return line.strokedPath(StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round, dash: Self.dash))
    }
}

#Preview("チケットの形") {
    let shape = TicketShape(cornerRadius: 16, stubHeight: 48)
    shape
        .fill(.pink)
        .overlay {
            DoubleLineBorder(shape: shape, color: AdaptiveColor(light: 0x1A0F16, dark: 0xFF7EB3))
        }
        .overlay(alignment: .bottom) {
            TicketPerforation()
                .fill(.white.opacity(0.6))
                .frame(height: TicketPerforation.lineWidth)
                .padding(.horizontal, 18)
                .padding(.bottom, 47)
        }
        .frame(width: 320, height: 200)
        .padding()
}
