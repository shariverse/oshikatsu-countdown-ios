//
//  OshikatsuMotifTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
@testable import OshiCon
import SwiftUI
import Testing

/// 推し活のモチーフ（チケット・チェキ・缶バッジ・リボン）の形と寸法。
struct OshikatsuMotifTests {
    private let rect = CGRect(x: 0, y: 0, width: 300, height: 200)

    @Test("チケットの形は、半券の上の端（ミシン目）の左右に半円の切り欠きを入れる")
    func ticketNotches() {
        let path = TicketShape(cornerRadius: 16, stubHeight: 50).path(in: rect)
        // ミシン目は下の辺から 50 上（y = 150）
        #expect(path.contains(CGPoint(x: 150, y: 100)))
        #expect(path.contains(CGPoint(x: 150, y: 150)))
        // 左右の辺から半径 9 の内側は切り欠き
        #expect(!path.contains(CGPoint(x: 4, y: 150)))
        #expect(!path.contains(CGPoint(x: 296, y: 150)))
        #expect(!path.contains(CGPoint(x: 2, y: 144)))
        // 切り欠きのすぐ外はカードの中
        #expect(path.contains(CGPoint(x: 11, y: 150)))
        #expect(path.contains(CGPoint(x: 289, y: 150)))
        #expect(path.contains(CGPoint(x: 4, y: 165)))
        #expect(path.contains(CGPoint(x: 4, y: 135)))
    }

    @Test("半券の高さをまだ測っていないとき（0）と、カードより高いときは、切り欠きを入れない")
    func ticketWithoutStub() {
        for stubHeight in [CGFloat(0), -10, 200, 240] {
            let path = TicketShape(cornerRadius: 16, stubHeight: stubHeight).path(in: rect)
            #expect(path.contains(CGPoint(x: 1, y: 100)), "\(stubHeight)")
            #expect(path.contains(CGPoint(x: 299, y: 100)), "\(stubHeight)")
            #expect(path.boundingRect == rect, "\(stubHeight)")
        }
    }

    @Test("内側に寄せたチケットの形は、切り欠きの中心を変えずに、寄せた分だけ切り欠きを大きくする（二重の線が切り欠きに沿う）")
    func ticketInset() {
        let path = TicketShape(cornerRadius: 16, stubHeight: 50).inset(by: 4).path(in: rect)
        #expect(path.boundingRect == rect.insetBy(dx: 4, dy: 4))
        // 元の辺（x = 0）から半径 9 + 4 = 13 の内側は切り欠き
        #expect(!path.contains(CGPoint(x: 12, y: 150)))
        #expect(path.contains(CGPoint(x: 14, y: 150)))
        #expect(!path.contains(CGPoint(x: 288, y: 150)))
        #expect(path.contains(CGPoint(x: 286, y: 150)))
        // 寄せを重ねても足し合わせる
        let twice = TicketShape(cornerRadius: 16, stubHeight: 50).inset(by: 2).inset(by: 2).path(in: rect)
        #expect(twice.boundingRect == path.boundingRect)
    }

    @Test("リボンの札の形は、右の端の中ほどに切れ込みを入れる")
    func ribbonNotch() {
        let path = RibbonShape().path(in: CGRect(x: 0, y: 0, width: 120, height: 30))
        #expect(path.contains(CGPoint(x: 60, y: 15)))
        #expect(path.contains(CGPoint(x: 1, y: 15)))
        // 右の端は、上下の角まで札で、中ほどは切れ込み
        #expect(path.contains(CGPoint(x: 119, y: 1)))
        #expect(path.contains(CGPoint(x: 119, y: 29)))
        #expect(!path.contains(CGPoint(x: 118, y: 15)))
        #expect(path.contains(CGPoint(x: 110, y: 15)))
    }

    @Test("チェキの枠は、写真の下の余白を広く取り、ハートを下の余白に収める")
    func chekiLayout() {
        let layout = ChekiPhotoLayout(width: 84)
        #expect(layout.height == 106)
        #expect(layout.border == 5)
        #expect(layout.bottomBorder == 17)
        #expect(layout.photoSize == CGSize(width: 74, height: 84))
        #expect(layout.heartSize < layout.bottomBorder)
        // 大きさを変えても、縦横の比は変わらない
        let large = ChekiPhotoLayout(width: 168)
        #expect(large.height == 212)
        #expect(large.photoSize == CGSize(width: 148, height: 168))
    }

    @Test("傾けたチェキが収まる大きさは、傾けない枠より大きく、傾きの向きによらない")
    func chekiBoundingSize() {
        let layout = ChekiPhotoLayout(width: 84)
        #expect(layout.boundingSize(tiltDegrees: 0) == CGSize(width: 84, height: 106))
        let tilted = layout.boundingSize(tiltDegrees: 5)
        #expect(tilted.width > 84)
        #expect(tilted.height > 106)
        #expect(tilted == layout.boundingSize(tiltDegrees: -5))
        // 5 度では、幅は高さの sin の分（約 9pt）だけ広がる
        #expect(abs(tilted.width - (84 * cos(5 * .pi / 180) + 106 * sin(5 * .pi / 180))) < 0.001)
    }

    @Test("缶バッジの輪の太さは、アバターの写真の縁取りと同じ（一辺の 1/16、2pt 以上）。ツヤは左上に収まる")
    func canBadgeLayout() {
        #expect(CanBadgeLayout(size: 48).ringWidth == 3)
        #expect(CanBadgeLayout(size: 24).ringWidth == 2)
        for size in [CGFloat(32), 44, 48, 96] {
            let layout = CanBadgeLayout(size: size)
            let bounds = CGRect(x: 0, y: 0, width: size, height: size)
            #expect(bounds.contains(layout.glossFrame), "\(size)")
            #expect(layout.glossFrame.midX < bounds.midX, "\(size)")
            #expect(layout.glossFrame.maxY < bounds.midY, "\(size)")
        }
    }

    @Test("見出しの飾りの印は、リボンの札に入れる SF Symbols の名前で引ける")
    func headingOrnamentSymbol() {
        #expect(AppTheme.shipping.decoration.headingOrnament.symbolName == "heart.fill")
        #expect(AppTheme.HeadingOrnament.none.symbolName == nil)
    }
}
