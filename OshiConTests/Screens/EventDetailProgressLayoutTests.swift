//
//  EventDetailProgressLayoutTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct EventDetailProgressLayoutTests {
    @Test("塗りの幅は、バーの幅に進み具合を掛けたもの", arguments: [(0.0, 0.0), (0.25, 75.0), (0.76, 228.0), (1.0, 300.0)])
    func fillWidth(progress: Double, width: Double) {
        #expect(abs(EventDetailProgressLayout.fillWidth(progress: progress, barWidth: 300) - width) < 0.001)
    }

    @Test("進み具合が 0〜1 の外でも、塗りはバーの中に収める")
    func fillWidthClamped() {
        #expect(EventDetailProgressLayout.fillWidth(progress: -0.5, barWidth: 300) == 0)
        #expect(EventDetailProgressLayout.fillWidth(progress: 1.5, barWidth: 300) == 300)
        #expect(EventDetailProgressLayout.fillWidth(progress: 0.5, barWidth: -10) == 0)
    }

    @Test("ハートの中心は塗りの先端。0% と 100% では半分だけバーの端からはみ出す")
    func heartOffset() {
        let heart = EventDetailProgressLayout.heartSize
        #expect(EventDetailProgressLayout.heartOffset(progress: 0.5, barWidth: 300) == 150 - heart / 2)
        #expect(EventDetailProgressLayout.heartOffset(progress: 0, barWidth: 300) == -heart / 2)
        #expect(EventDetailProgressLayout.heartOffset(progress: 1, barWidth: 300) == 300 - heart / 2)
        // ハートはバーより太く、バーの上下にはみ出して先端だとわかる
        #expect(heart > EventDetailProgressLayout.barHeight)
    }
}
