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
        #expect(PhotoCropAccessibility.value(of: crop, locale: DomainFixtures.english) == "Zoom 1.5×, rotation -12°")
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
