//
//  PhotoCropRectangleTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
@testable import OshiCon
import SwiftUI
import Testing

/// 長方形の枠（背景の写真の約 9:19.5 の縦長など）の範囲の計算と、調整画面の枠の大きさ。
struct PhotoCropRectangleTests {
    private static let tolerance: CGFloat = 1e-6
    private static let background = PhotoCrop.backgroundAspectRatio

    /// 横長・縦長・とても縦長・正方形・小さい画像。
    nonisolated static let imageSizes: [CGSize] = [
        CGSize(width: 4_032, height: 3_024),
        CGSize(width: 3_000, height: 4_000),
        CGSize(width: 1_000, height: 4_000),
        CGSize(width: 2_000, height: 2_000),
        CGSize(width: 120, height: 80)
    ]

    /// 0°・45°・90°・負・360° を超える角度。
    nonisolated static let angles: [Double] = [0, 12, 45, 90, -30, -135, 400, -725]

    /// 背景の写真の縦横比の範囲。
    private static func backgroundCrop(_ size: CGSize, zoom: CGFloat, rotation: Angle = .zero, center: CGPoint) -> PhotoCrop {
        PhotoCrop(imageSize: size, aspectRatio: background, zoom: zoom, rotation: rotation, center: center)
    }

    /// 切り抜く長方形の隅がすべて画像の中にあるか（= 枠の隅が空かない）。
    private static func covers(_ crop: PhotoCrop) -> Bool {
        crop.region.corners.allSatisfy { corner in
            corner.x >= -1e-3 && corner.x <= crop.imageSize.width + 1e-3
                && corner.y >= -1e-3 && corner.y <= crop.imageSize.height + 1e-3
        }
    }

    // MARK: - 初期値

    @Test("背景の枠の縦横比は 9:19.5")
    func backgroundAspectRatio() {
        #expect(abs(PhotoCrop.backgroundAspectRatio - 9 / 19.5) < Self.tolerance)
        #expect(PhotoCrop.backgroundAspectRatio < 1)
    }

    @Test("横長の写真では、写真の高さいっぱいの縦長の長方形が中央に来る")
    func initialCropOnLandscape() {
        let crop = PhotoCrop(imageSize: CGSize(width: 4_000, height: 3_000), aspectRatio: Self.background)
        #expect(crop.zoom == 1)
        #expect(abs(crop.region.size.height - 3_000) < Self.tolerance)
        #expect(abs(crop.region.size.width - 3_000 * Self.background) < Self.tolerance)
        #expect(crop.region.center == CGPoint(x: 2_000, y: 1_500))
        #expect(crop.clamped() == crop)
        #expect(Self.covers(crop))
    }

    @Test("枠より細長い写真では、写真の幅いっぱいの長方形が中央に来る")
    func initialCropOnTallImage() {
        let crop = PhotoCrop(imageSize: CGSize(width: 1_000, height: 4_000), aspectRatio: Self.background)
        #expect(abs(crop.region.size.width - 1_000) < Self.tolerance)
        #expect(abs(crop.region.size.height - 1_000 / Self.background) < Self.tolerance)
        #expect(crop.clamped() == crop)
    }

    @Test("縦横比を渡さなければ正方形（推しの丸の範囲）", arguments: imageSizes)
    func defaultIsSquare(size: CGSize) {
        let crop = PhotoCrop(imageSize: size)
        #expect(crop.aspectRatio == 1)
        #expect(crop.region.size.width == crop.region.size.height)
        #expect(crop.region.side == min(size.width, size.height))
    }

    @Test("おかしな縦横比（0・負・無限）は正方形にする", arguments: [0, -1, CGFloat.infinity, CGFloat.nan])
    func invalidAspectRatioFallsBackToSquare(ratio: CGFloat) {
        #expect(PhotoCrop(imageSize: CGSize(width: 400, height: 300), aspectRatio: ratio).aspectRatio == 1)
    }

    // MARK: - 拡大率の上限・下限

    @Test("縦長の枠を 90° 回すと、横長の写真では枠を覆う下限が 1 より小さくなる（外接矩形の幅と高さで決まる）")
    func minimumZoomOfRotatedRectangle() {
        var crop = PhotoCrop(imageSize: CGSize(width: 4_000, height: 3_000), aspectRatio: Self.background)
        #expect(abs(crop.minimumZoom - 1) < Self.tolerance)
        crop.rotation = .degrees(90)
        // 回した枠の外接矩形は 幅 3000・高さ 3000 × 9/19.5。幅が写真の 4000 に収まる倍率 0.75 が下限
        #expect(abs(crop.minimumZoom - 0.75) < Self.tolerance)
        crop.rotation = .degrees(30)
        let base = crop.baseSize
        let cosine = CGFloat(cos(Double.pi / 6))
        let sine: CGFloat = 0.5
        let expected = max(
            (base.width * cosine + base.height * sine) / 4_000,
            (base.width * sine + base.height * cosine) / 3_000
        )
        #expect(abs(crop.minimumZoom - expected) < Self.tolerance)
    }

    @Test("拡大の上限は、切り抜く範囲の短い辺が 360px を下回らない倍率")
    func maximumZoomKeepsMinimumPixelsOnShortSide() {
        var crop = PhotoCrop(imageSize: CGSize(width: 7_800, height: 3_600), aspectRatio: Self.background)
        let baseWidth = 3_600 * Self.background
        #expect(abs(crop.maximumZoom - baseWidth / 360) < Self.tolerance)
        crop.zoom = 50
        let clamped = crop.clamped()
        #expect(abs(clamped.region.size.width - PhotoCrop.minimumCropPixelLength) < Self.tolerance)
        #expect(clamped.region.size.height > clamped.region.size.width)
    }

    @Test("枠の短い辺が 360px より小さい写真は拡大できない（上限が下限と同じ）")
    func smallImageCannotZoomIn() {
        var crop = PhotoCrop(imageSize: CGSize(width: 120, height: 80), aspectRatio: Self.background)
        #expect(crop.maximumZoom == crop.minimumZoom)
        crop.zoom = 3
        #expect(crop.clamped().zoom == 1)
    }

    // MARK: - はみ出しの補正

    @Test("枠から外れる移動・縮小は、枠の隅が空かない位置まで戻す", arguments: imageSizes, angles)
    func clampedCropAlwaysCoversFrame(size: CGSize, degrees: Double) {
        let offsets: [CGPoint] = [
            CGPoint(x: -10_000, y: -10_000), CGPoint(x: 10_000, y: 10_000),
            CGPoint(x: -10_000, y: 10_000), CGPoint(x: size.width / 2, y: -10_000), .zero
        ]
        for zoom: CGFloat in [0.3, 1, 1.5, 3, 100] {
            for center in offsets {
                let clamped = Self.backgroundCrop(size, zoom: zoom, rotation: .degrees(degrees), center: center).clamped()
                #expect(Self.covers(clamped), "zoom \(zoom) center \(center)")
                #expect(clamped.zoom >= clamped.minimumZoom - Self.tolerance)
                #expect(clamped.zoom <= clamped.maximumZoom + Self.tolerance)
                let again = clamped.clamped()
                #expect(abs(again.center.x - clamped.center.x) < Self.tolerance)
                #expect(abs(again.center.y - clamped.center.y) < Self.tolerance)
            }
        }
    }

    @Test("横長の写真に縦長の枠は、回転なしなら横にだけ動かせ、端で止まる")
    func portraitFrameMovesHorizontallyOnLandscape() {
        let size = CGSize(width: 4_000, height: 3_000)
        let clamped = Self.backgroundCrop(size, zoom: 1, center: .zero).clamped()
        let halfWidth = 3_000 * Self.background / 2
        #expect(abs(clamped.center.x - halfWidth) < Self.tolerance)
        #expect(clamped.center.y == 1_500)
        let topLeft = clamped.region.corners[0]
        #expect(abs(topLeft.x) < Self.tolerance && abs(topLeft.y) < Self.tolerance)
        // 右の端まで動かしても、枠の右の隅は写真の右の端で止まる
        let right = Self.backgroundCrop(size, zoom: 1, center: CGPoint(x: 9_000, y: 9_000)).clamped()
        #expect(abs(right.region.boundingBox.maxX - 4_000) < Self.tolerance)
        #expect(right.center.y == 1_500)
    }

    @Test("長方形の隅と外接矩形は、枠の幅と高さで回る")
    func rectangleCornersAndBoundingBox() {
        let crop = PhotoCrop(
            imageSize: CGSize(width: 4_000, height: 3_000),
            aspectRatio: 0.5,
            zoom: 2,
            rotation: .degrees(90),
            center: CGPoint(x: 2_000, y: 1_500)
        )
        // 枠は 幅 750・高さ 1500（拡大率 1 で 1500×3000）
        #expect(abs(crop.region.size.width - 750) < Self.tolerance)
        #expect(abs(crop.region.size.height - 1_500) < Self.tolerance)
        // 右に 90° 回したので、枠の左上の隅は画像では左下に来る
        let topLeft = crop.region.corners[0]
        #expect(abs(topLeft.x - 1_250) < 1e-6)
        #expect(abs(topLeft.y - 1_875) < 1e-6)
        let box = crop.region.boundingBox
        #expect(abs(box.width - 1_500) < 1e-6)
        #expect(abs(box.height - 750) < 1e-6)
    }

    // MARK: - 変わっていないか

    @Test("縦横比が違えば、同じ写真・同じ位置でも変わっている")
    func aspectRatioChangeIsAChange() {
        let size = CGSize(width: 4_000, height: 3_000)
        let square = PhotoCrop(imageSize: size)
        let portrait = PhotoCrop(imageSize: size, aspectRatio: Self.background)
        #expect(portrait.isUnchanged(from: portrait))
        #expect(!portrait.isUnchanged(from: square))
        let frame = CGSize(width: 180, height: 390)
        #expect(!portrait.dragged(by: CGSize(width: 10, height: 0), frameSize: frame).isUnchanged(from: portrait))
    }

    // MARK: - 画面の枠への配置

    @Test("配置: 拡大率は 拡大率 × 枠の幅 ÷ 切り抜く範囲の幅（拡大率 1）")
    func layoutUsesFrameWidth() {
        let crop = Self.backgroundCrop(CGSize(width: 4_000, height: 3_000), zoom: 2, center: CGPoint(x: 2_000, y: 1_500))
        let frame = CGSize(width: 360, height: 360 / Self.background)
        let layout = crop.layout(frameSize: frame)
        #expect(abs(layout.scale - 2 * 360 / (3_000 * Self.background)) < Self.tolerance)
        #expect(layout.offset == .zero)
        // 枠の高さに写る画素は、切り抜く範囲の高さ
        #expect(abs(frame.height / layout.scale - crop.region.size.height) < 1e-6)
    }

    @Test("正方形の枠の一辺で求める配置は、同じ大きさの枠で求める配置と同じ")
    func squareLayoutMatchesFrameSize() {
        let crop = PhotoCrop(
            imageSize: CGSize(width: 3_000, height: 4_000),
            zoom: 1.8,
            rotation: .degrees(20),
            center: CGPoint(x: 1_100, y: 2_600)
        )
        let frame = CGSize(width: 280, height: 280)
        let bySide = crop.layout(frameSide: 280)
        let bySize = crop.layout(frameSize: frame)
        #expect(bySide.scale == bySize.scale)
        #expect(bySide.offset == bySize.offset)
        let move = CGSize(width: 12, height: 5)
        #expect(crop.dragged(by: move, frameSide: 280) == crop.dragged(by: move, frameSize: frame))
    }

    @Test("縦長の枠でも、ドラッグした量だけ画像が動き、配置の移動量に戻る", arguments: angles)
    func dragRoundTripsOnRectangle(degrees: Double) {
        let crop = PhotoCrop(
            imageSize: CGSize(width: 4_032, height: 3_024),
            aspectRatio: Self.background,
            zoom: 2,
            rotation: .degrees(degrees),
            center: CGPoint(x: 2_000, y: 1_500)
        )
        let frame = CGSize(width: 354, height: 767)
        let before = crop.layout(frameSize: frame).offset
        let moved = crop.dragged(by: CGSize(width: 24, height: -40), frameSize: frame)
        let after = moved.layout(frameSize: frame).offset
        #expect(abs(after.width - before.width - 24) < 1e-6)
        #expect(abs(after.height - before.height + 40) < 1e-6)
    }

    // MARK: - 調整画面の枠の大きさ

    @Test("縦長の枠は、余白を引いた範囲の高さに合わせる（iPhone の縦・横）")
    func backgroundFrameOnIPhone() {
        let portrait = PhotoCropLayout.frameSize(in: CGSize(width: 402, height: 800), aspectRatio: Self.background)
        #expect(abs(portrait.height - 768) < Self.tolerance)
        #expect(abs(portrait.width - 768 * Self.background) < Self.tolerance)
        let landscape = PhotoCropLayout.frameSize(in: CGSize(width: 874, height: 340), aspectRatio: Self.background)
        #expect(abs(landscape.height - 308) < Self.tolerance)
        #expect(abs(landscape.width - 308 * Self.background) < Self.tolerance)
    }

    @Test("幅が足りなければ幅に合わせる")
    func backgroundFrameLimitedByWidth() {
        let size = PhotoCropLayout.frameSize(in: CGSize(width: 300, height: 1_000), aspectRatio: Self.background)
        #expect(abs(size.width - 268) < Self.tolerance)
        #expect(abs(size.height - 268 / Self.background) < Self.tolerance)
    }

    @Test("iPad の大きな画面では、短い辺を 560pt で止める（縦横比はそのまま）")
    func backgroundFrameIsCappedOnIPad() {
        let size = PhotoCropLayout.frameSize(in: CGSize(width: 1_032, height: 1_300), aspectRatio: Self.background)
        #expect(size.width == 560)
        #expect(abs(size.height - 560 / Self.background) < Self.tolerance)
        let wide = PhotoCropLayout.frameSize(in: CGSize(width: 3_000, height: 1_300), aspectRatio: 2)
        #expect(wide.height == 560)
        #expect(wide.width == 1_120)
    }

    @Test("正方形の枠の大きさは、枠の一辺と同じ", arguments: [
        CGSize(width: 402, height: 700), CGSize(width: 874, height: 340), CGSize(width: 1_032, height: 1_300), .zero
    ])
    func squareFrameSizeMatchesFrameSide(size: CGSize) {
        let frame = PhotoCropLayout.frameSize(in: size, aspectRatio: 1)
        #expect(frame.width == PhotoCropLayout.frameSide(in: size))
        #expect(frame.height == frame.width)
    }

    @Test("配置の前（大きさ 0）でも負にならない")
    func backgroundFrameIsNotNegative() {
        let size = PhotoCropLayout.frameSize(in: .zero, aspectRatio: Self.background)
        #expect(size.width == 0)
        #expect(size.height == 0)
    }

    @Test("縦長の枠でも、ジェスチャーの量を当てると写真が指と同じだけ動き、幅 0 の枠では動かさない")
    func gestureOnRectangle() {
        let base = Self.backgroundCrop(CGSize(width: 4_000, height: 3_000), zoom: 1.5, center: CGPoint(x: 2_000, y: 1_500))
        let frame = CGSize(width: 354, height: 767)
        let move = CGSize(width: 30, height: 0)
        let moved = PhotoCropGesture.apply(to: base, translation: move, magnification: 1, rotation: .zero, frameSize: frame)
        let before = base.layout(frameSize: frame).offset
        let after = moved.layout(frameSize: frame).offset
        #expect(abs(after.width - before.width - 30) < 1e-6)
        let still = PhotoCropGesture.apply(to: base, translation: move, magnification: 1, rotation: .zero, frameSize: .zero)
        #expect(still == base)
    }

    // MARK: - 枠の形

    @Test("枠の形は、丸も角の丸い長方形も枠いっぱいに描く", arguments: [PhotoCropShape.circle, .roundedRectangle])
    func shapeFillsFrame(shape: PhotoCropShape) {
        let rect = CGRect(x: 10, y: 20, width: 180, height: 390)
        let bounds = shape.path(in: rect).boundingRect
        #expect(abs(bounds.minX - rect.minX) < 1e-6 && abs(bounds.maxX - rect.maxX) < 1e-6)
        #expect(abs(bounds.minY - rect.minY) < 1e-6 && abs(bounds.maxY - rect.maxY) < 1e-6)
    }

    @Test("角の丸い長方形は、角を丸めて中央の辺はまっすぐ（丸とは違う形）")
    func roundedRectangleKeepsEdges() {
        let rect = CGRect(x: 0, y: 0, width: 180, height: 390)
        let rounded = PhotoCropShape.roundedRectangle.path(in: rect)
        let circle = PhotoCropShape.circle.path(in: rect)
        // 左の辺の上寄り（角の丸みより内側）は、長方形には入り、楕円には入らない
        let nearEdge = CGPoint(x: 1, y: 60)
        #expect(rounded.contains(nearEdge))
        #expect(!circle.contains(nearEdge))
        // 隅そのものは丸めてあるので入らない
        #expect(!rounded.contains(CGPoint(x: 0.5, y: 0.5)))
    }
}
