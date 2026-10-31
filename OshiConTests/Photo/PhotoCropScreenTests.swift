//
//  PhotoCropScreenTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
@testable import OshiCon
import SwiftUI
import Testing

/// 写真の調整画面の、画面から切り離した決まり（枠の大きさ・ジェスチャーの途中の制限・読み上げの操作・配色）。
struct PhotoCropScreenTests {
    private let size = CGSize(width: 3_000, height: 4_000)

    // MARK: - 枠の大きさ

    @Test("枠の一辺は、短い辺から余白を引いた大きさ（iPhone の縦・横）")
    func frameSideFromShortSide() {
        #expect(PhotoCropLayout.frameSide(in: CGSize(width: 402, height: 700)) == 370)
        #expect(PhotoCropLayout.frameSide(in: CGSize(width: 874, height: 340)) == 308)
    }

    @Test("iPad の大きな画面では 560pt で止める")
    func frameSideIsCappedOnIPad() {
        #expect(PhotoCropLayout.frameSide(in: CGSize(width: 1_032, height: 1_300)) == 560)
    }

    @Test("配置の前（大きさ 0）でも負にならない")
    func frameSideIsNotNegative() {
        #expect(PhotoCropLayout.frameSide(in: .zero) == 0)
    }

    // MARK: - ジェスチャーの途中

    @Test("ジェスチャーの途中は、下限の半分から上限の 2 倍までに抑える")
    func gestureLimits() {
        var crop = PhotoCrop(imageSize: size)
        crop.zoom = 0.1
        #expect(PhotoCropLayout.limitedWhileGesturing(crop).zoom == 0.5)
        crop.zoom = 100
        #expect(abs(PhotoCropLayout.limitedWhileGesturing(crop).zoom - crop.maximumZoom * 2) < 1e-9)
        crop.zoom = 2
        #expect(PhotoCropLayout.limitedWhileGesturing(crop).zoom == 2)
    }

    // MARK: - ジェスチャーの量

    @Test("始めたときの範囲に、始めたときからの量を当てる（何度呼んでも同じ量なら同じ結果）")
    func gestureIsAppliedToBase() {
        let base = PhotoCrop(imageSize: size, zoom: 1.5, rotation: .zero, center: CGPoint(x: 1_500, y: 2_000))
        let move = CGSize(width: 30, height: 0)
        let first = PhotoCropGesture.apply(to: base, translation: move, magnification: 1.2, rotation: .degrees(10), frameSide: 300)
        let again = PhotoCropGesture.apply(to: base, translation: move, magnification: 1.2, rotation: .degrees(10), frameSide: 300)
        #expect(first == again)
        #expect(abs(first.zoom - 1.8) < 1e-9)
        #expect(abs(first.rotation.degrees - 10) < 1e-9)
        // 拡大・回転したあとの見た目で、写真が指と同じだけ動く
        let before = base.zoomed(by: 1.2).rotated(by: .degrees(10)).layout(frameSide: 300).offset
        let after = first.layout(frameSide: 300).offset
        #expect(abs(after.width - before.width - 30) < 1e-6)
        #expect(abs(after.height - before.height) < 1e-6)
    }

    @Test("量が無ければ始めたときの範囲のまま（中断した後に前回の量が残らない）")
    func noGestureKeepsBase() {
        let base = PhotoCrop(imageSize: size, zoom: 2, rotation: .degrees(30), center: CGPoint(x: 1_200, y: 1_800))
        #expect(PhotoCropGesture.apply(to: base, translation: .zero, magnification: 1, rotation: .zero, frameSide: 300) == base)
    }

    @Test("ジェスチャーの途中の拡大率は制限に収め、おかしな倍率や大きさ 0 の枠では動かさない")
    func gestureGuards() {
        let base = PhotoCrop(imageSize: size)
        #expect(PhotoCropGesture.apply(to: base, translation: .zero, magnification: 0.01, rotation: .zero, frameSide: 300).zoom == 0.5)
        #expect(PhotoCropGesture.apply(to: base, translation: .zero, magnification: .nan, rotation: .zero, frameSide: 300) == base)
        let move = CGSize(width: 50, height: 50)
        let moved = PhotoCropGesture.apply(to: base, translation: move, magnification: 1, rotation: .zero, frameSide: 0)
        #expect(moved == base)
    }

    @Test("先に終わったジェスチャー（片方の指を離した拡大・回転）は、最後の量を保つ")
    func amountKeepsLastValues() {
        var amount = PhotoCropGesture.Amount()
        amount.update(translation: CGSize(width: 10, height: 0), magnification: 1.5, rotation: .degrees(20))
        amount.update(translation: CGSize(width: 40, height: 5), magnification: nil, rotation: nil)
        #expect(amount.translation == CGSize(width: 40, height: 5))
        #expect(amount.magnification == 1.5)
        #expect(amount.rotation == .degrees(20))
    }

    @Test("元に戻すときは、今の角度に最も近い同じ見た目の角度に戻す（何周も回らない）")
    func resetUsesNearestTurn() {
        let initial = PhotoCrop(imageSize: size)
        var current = initial
        current.rotation = .degrees(400)
        current.zoom = 2
        let reset = PhotoCropGesture.reset(current, to: initial)
        #expect(abs(reset.rotation.degrees - 360) < 1e-9)
        #expect(reset.zoom == 1)
        current.rotation = .degrees(-170)
        #expect(abs(PhotoCropGesture.reset(current, to: initial).rotation.degrees) < 1e-9)
        current.rotation = .degrees(-200)
        #expect(abs(PhotoCropGesture.reset(current, to: initial).rotation.degrees + 360) < 1e-9)
    }

    // MARK: - 読み上げの操作

    @Test("拡大・縮小は 1.25 倍ずつで、上限・下限で止まる")
    func accessibilityZoom() {
        let initial = PhotoCrop(imageSize: size)
        let zoomedIn = PhotoCropAccessibility.zoomedIn(initial)
        #expect(abs(zoomedIn.zoom - 1.25) < 1e-9)
        #expect(PhotoCropAccessibility.zoomedOut(zoomedIn).zoom == 1)
        // 下限より小さくはしない
        #expect(PhotoCropAccessibility.zoomedOut(initial).zoom == 1)
        // 上限より大きくはしない
        var crop = initial
        for _ in 0..<40 {
            crop = PhotoCropAccessibility.zoomedIn(crop)
        }
        #expect(abs(crop.zoom - crop.maximumZoom) < 1e-9)
    }

    @Test("回転は 5° ずつで、枠の隅が空かないよう拡大率を補正する")
    func accessibilityRotation() {
        let initial = PhotoCrop(imageSize: size)
        let right = PhotoCropAccessibility.rotated(initial, clockwise: true)
        #expect(abs(right.rotation.degrees - 5) < 1e-9)
        #expect(right.zoom >= right.minimumZoom - 1e-9)
        #expect(right.zoom > 1)
        let left = PhotoCropAccessibility.rotated(initial, clockwise: false)
        #expect(abs(left.rotation.degrees + 5) < 1e-9)
    }

    @Test("読み上げの値は拡大率と回転の角度（日本語・英語）")
    func accessibilityValue() {
        var crop = PhotoCrop(imageSize: size)
        crop.zoom = 1.5
        crop.rotation = .degrees(-372)
        #expect(PhotoCropAccessibility.value(of: crop, locale: DomainFixtures.japanese) == "拡大 1.5 倍、回転 -12 度")
        #expect(PhotoCropAccessibility.value(of: crop, locale: DomainFixtures.english) == "Zoom 1.5 times, rotation -12 degrees")
    }

    // MARK: - 配色

    @Test("黒い地の上の見出し・ボタンの文字は 4.5:1 以上（テーマのダークの色）")
    func barTextContrast() {
        let palette = AppTheme.shipping.palette
        let black = RGBColor(hex: 0x000000)
        #expect(palette.onSurface.dark.contrastRatio(with: black) >= 4.5)
        #expect(palette.brand.dark.contrastRatio(with: black) >= 4.5)
    }

    // MARK: - 確かめ用の画像

    @Test("確かめ用の画像は 1600×1200")
    func previewImageSize() {
        let image = PhotoCropPreviewImage.make()
        #expect(image.width == 1_600)
        #expect(image.height == 1_200)
    }
}
