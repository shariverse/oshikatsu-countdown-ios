//
//  PhotoCropTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
@testable import OshiCon
import SwiftUI
import Testing

struct PhotoCropTests {
    private static let tolerance: CGFloat = 1e-6

    /// 縦長・横長・正方形・小さい画像。
    nonisolated static let imageSizes: [CGSize] = [
        CGSize(width: 3_000, height: 4_000),
        CGSize(width: 4_032, height: 3_024),
        CGSize(width: 2_000, height: 2_000),
        CGSize(width: 120, height: 80)
    ]

    /// 0°・45°・90°・負・360° を超える角度。
    nonisolated static let angles: [Double] = [0, 12, 45, 90, -30, -135, 400, -725]

    /// 切り抜く正方形の隅がすべて画像の中にあるか（= 枠の隅が空かない）。
    private static func covers(_ crop: PhotoCrop) -> Bool {
        crop.region.corners.allSatisfy { corner in
            corner.x >= -tolerance && corner.x <= crop.imageSize.width + tolerance
                && corner.y >= -tolerance && corner.y <= crop.imageSize.height + tolerance
        }
    }

    // MARK: - 初期値

    @Test("初期値は、回転なし・中央で、画像の短い辺いっぱいの正方形", arguments: imageSizes)
    func initialCrop(size: CGSize) {
        let crop = PhotoCrop(imageSize: size)
        #expect(crop.zoom == 1)
        #expect(crop.rotation == .zero)
        #expect(crop.region.center == CGPoint(x: size.width / 2, y: size.height / 2))
        #expect(crop.region.side == min(size.width, size.height))
        #expect(crop.clamped() == crop)
        #expect(Self.covers(crop))
    }

    // MARK: - 拡大率の上限・下限

    @Test("枠を覆う最小の拡大率は |cos θ| + |sin θ|（0° と 90° で 1、45° で √2）")
    func minimumZoomDependsOnRotation() {
        var crop = PhotoCrop(imageSize: CGSize(width: 3_000, height: 4_000))
        #expect(abs(crop.minimumZoom - 1) < Self.tolerance)
        crop.rotation = .degrees(45)
        #expect(abs(crop.minimumZoom - 2.squareRoot()) < Self.tolerance)
        crop.rotation = .degrees(90)
        #expect(abs(crop.minimumZoom - 1) < Self.tolerance)
        crop.rotation = .degrees(-45)
        #expect(abs(crop.minimumZoom - 2.squareRoot()) < Self.tolerance)
    }

    @Test("拡大の上限は、切り抜く範囲の一辺が 360px を下回らない倍率")
    func maximumZoomKeepsMinimumPixels() {
        var crop = PhotoCrop(imageSize: CGSize(width: 3_600, height: 4_800))
        #expect(abs(crop.maximumZoom - 10) < Self.tolerance)
        crop.zoom = 50
        let clamped = crop.clamped()
        #expect(abs(clamped.zoom - 10) < Self.tolerance)
        #expect(abs(clamped.region.side - PhotoCrop.minimumCropPixelLength) < Self.tolerance)
    }

    @Test("下限より小さい拡大率は、回転角に応じた下限まで戻す", arguments: angles)
    func zoomBelowMinimumIsRaised(degrees: Double) {
        let crop = PhotoCrop(imageSize: CGSize(width: 4_032, height: 3_024), zoom: 0.3, rotation: .degrees(degrees), center: .zero)
        let clamped = crop.clamped()
        #expect(abs(clamped.zoom - PhotoCrop.rotationFactor(.degrees(degrees))) < Self.tolerance)
        #expect(Self.covers(clamped))
    }

    @Test("枠より小さい画像は拡大できない（上限が下限と同じ）")
    func smallImageCannotZoomIn() {
        var crop = PhotoCrop(imageSize: CGSize(width: 120, height: 80))
        #expect(crop.maximumZoom == crop.minimumZoom)
        crop.zoom = 3
        #expect(crop.clamped().zoom == 1)
        crop.rotation = .degrees(30)
        crop.zoom = 3
        #expect(abs(crop.clamped().zoom - PhotoCrop.rotationFactor(.degrees(30))) < Self.tolerance)
        #expect(Self.covers(crop.clamped()))
    }

    // MARK: - はみ出しの補正

    @Test("枠から外れる移動は、枠の隅が空かない位置まで戻す", arguments: imageSizes, angles)
    func clampedCropAlwaysCoversFrame(size: CGSize, degrees: Double) {
        let offsets: [CGPoint] = [
            CGPoint(x: -10_000, y: -10_000), CGPoint(x: 10_000, y: 10_000),
            CGPoint(x: -10_000, y: 10_000), CGPoint(x: size.width / 2, y: -10_000), .zero
        ]
        for zoom: CGFloat in [0.5, 1, 1.5, 3, 100] {
            for center in offsets {
                let clamped = PhotoCrop(imageSize: size, zoom: zoom, rotation: .degrees(degrees), center: center).clamped()
                #expect(Self.covers(clamped), "zoom \(zoom) center \(center)")
                #expect(clamped.zoom >= clamped.minimumZoom - Self.tolerance)
                #expect(clamped.zoom <= clamped.maximumZoom + Self.tolerance)
                // 補正した結果をもう一度補正しても変わらない
                let again = clamped.clamped()
                #expect(abs(again.center.x - clamped.center.x) < Self.tolerance)
                #expect(abs(again.center.y - clamped.center.y) < Self.tolerance)
            }
        }
    }

    @Test("枠の中にある位置は補正で動かさない")
    func validCenterIsKept() {
        let crop = PhotoCrop(imageSize: CGSize(width: 4_000, height: 3_000), zoom: 2, rotation: .zero, center: CGPoint(x: 1_200, y: 900))
        #expect(crop.clamped() == crop)
    }

    @Test("横長の画像は、回転なしなら横にだけ動かせる")
    func landscapeMovesHorizontally() {
        let crop = PhotoCrop(imageSize: CGSize(width: 4_000, height: 3_000), zoom: 1, rotation: .zero, center: .zero)
        let clamped = crop.clamped()
        #expect(clamped.center == CGPoint(x: 1_500, y: 1_500))
        #expect(clamped.region.corners[0] == .zero)
    }

    @Test("回転すると下限の拡大率でも隅に合わせて止まる（45° の正方形の画像は中央に戻る）")
    func rotatedSquareStaysCentered() {
        let crop = PhotoCrop(
            imageSize: CGSize(width: 2_000, height: 2_000),
            zoom: 1,
            rotation: .degrees(45),
            center: CGPoint(x: 1_900, y: 100)
        )
        let clamped = crop.clamped()
        #expect(abs(clamped.center.x - 1_000) < Self.tolerance)
        #expect(abs(clamped.center.y - 1_000) < Self.tolerance)
        #expect(Self.covers(clamped))
        // 外接矩形が画像にぴったり重なる
        let box = clamped.region.boundingBox
        #expect(abs(box.minX) < 1e-3 && abs(box.maxX - 2_000) < 1e-3)
    }

    // MARK: - 切り抜く範囲

    @Test("回転角は −180° より大きく 180° 以下にそろえる（360° を超えても同じ範囲）")
    func regionNormalizesRotation() {
        let size = CGSize(width: 3_000, height: 4_000)
        let center = CGPoint(x: 1_400, y: 2_100)
        let base = PhotoCrop(imageSize: size, zoom: 2, rotation: .degrees(30), center: center).region
        let wrapped = PhotoCrop(imageSize: size, zoom: 2, rotation: .degrees(390), center: center).region
        let negative = PhotoCrop(imageSize: size, zoom: 2, rotation: .degrees(-330), center: center).region
        #expect(abs(wrapped.rotation.degrees - 30) < 1e-9)
        #expect(abs(negative.rotation.degrees - 30) < 1e-9)
        #expect(abs(PhotoCrop.normalized(.degrees(180)).degrees - 180) < 1e-9)
        #expect(abs(PhotoCrop.normalized(.degrees(-180)).degrees - 180) < 1e-9)
        #expect(abs(PhotoCrop.normalized(.degrees(-190)).degrees - 170) < 1e-9)
        for (lhs, rhs) in zip(base.corners, wrapped.corners) {
            #expect(abs(lhs.x - rhs.x) < 1e-6 && abs(lhs.y - rhs.y) < 1e-6)
        }
        #expect(negative.side == base.side)
    }

    @Test("切り抜く一辺は、画像の短い辺 ÷ 拡大率")
    func regionSideFollowsZoom() {
        let crop = PhotoCrop(
            imageSize: CGSize(width: 3_000, height: 4_000),
            zoom: 2.5,
            rotation: .degrees(10),
            center: CGPoint(x: 1_500, y: 2_000)
        )
        #expect(abs(crop.region.side - 1_200) < Self.tolerance)
    }

    @Test("90° 回すと、枠の左上の隅は画像では左下にくる（右に回した画像の左上は、元の画像の左下）")
    func cornersFollowRotation() {
        let crop = PhotoCrop(
            imageSize: CGSize(width: 2_000, height: 2_000),
            zoom: 2,
            rotation: .degrees(90),
            center: CGPoint(x: 1_000, y: 1_000)
        )
        let topLeft = crop.region.corners[0]
        #expect(abs(topLeft.x - 500) < 1e-6)
        #expect(abs(topLeft.y - 1_500) < 1e-6)
    }

    // MARK: - 変わっていないか

    @Test("開いたときから動かしていなければ変わっていない（正方形・横長、元に戻して何周か回したあとも）", arguments: [
        CGSize(width: 1_440, height: 1_440), CGSize(width: 4_032, height: 3_024)
    ])
    func unchangedCrop(size: CGSize) {
        let initial = PhotoCrop(imageSize: size)
        #expect(initial.clamped().isUnchanged(from: initial))
        var turned = initial.clamped()
        turned.rotation = .degrees(720)
        #expect(turned.isUnchanged(from: initial))
    }

    @Test("拡大・移動・回転したら変わっている。補正で元に戻る移動は変わっていない")
    func changedCrop() {
        let initial = PhotoCrop(imageSize: CGSize(width: 1_440, height: 1_440))
        #expect(!initial.zoomed(by: 1.2).isUnchanged(from: initial))
        #expect(!initial.rotated(by: .degrees(5)).isUnchanged(from: initial))
        // 正方形の写真は拡大しないと動かせないので、少しずらしても補正で元に戻る
        #expect(initial.dragged(by: CGSize(width: 10, height: 0), frameSide: 300).isUnchanged(from: initial))
        let landscape = PhotoCrop(imageSize: CGSize(width: 4_032, height: 3_024))
        #expect(!landscape.dragged(by: CGSize(width: 10, height: 0), frameSide: 300).isUnchanged(from: landscape))
    }

    // MARK: - 画面の枠への配置

    @Test("配置: 拡大率は 拡大率 × 枠の一辺 ÷ 画像の短い辺、中央なら移動なし")
    func layoutOfInitialCrop() {
        let crop = PhotoCrop(imageSize: CGSize(width: 3_000, height: 4_000))
        let layout = crop.layout(frameSide: 300)
        #expect(abs(layout.scale - 0.1) < Self.tolerance)
        #expect(layout.offset == .zero)
    }

    @Test("ドラッグした量だけ画像が動き、配置の移動量に戻る", arguments: angles)
    func dragRoundTrips(degrees: Double) {
        let crop = PhotoCrop(
            imageSize: CGSize(width: 4_032, height: 3_024),
            zoom: 2,
            rotation: .degrees(degrees),
            center: CGPoint(x: 2_000, y: 1_500)
        )
        let before = crop.layout(frameSide: 320).offset
        let moved = crop.dragged(by: CGSize(width: 24, height: -40), frameSide: 320)
        let after = moved.layout(frameSide: 320).offset
        #expect(abs(after.width - before.width - 24) < 1e-6)
        #expect(abs(after.height - before.height + 40) < 1e-6)
    }

    @Test("右へドラッグすると、枠には画像の左側が写る（回転なし）")
    func dragRightShowsLeftSide() {
        let crop = PhotoCrop(imageSize: CGSize(width: 4_000, height: 3_000)).dragged(by: CGSize(width: 50, height: 0), frameSide: 300)
        #expect(crop.center.x < 2_000)
        #expect(crop.center.y == 1_500)
    }

    @Test("配置で描いた枠の中心には、範囲の中心の画素が写る", arguments: angles)
    func layoutMapsCenterToFrameCenter(degrees: Double) {
        let crop = PhotoCrop(
            imageSize: CGSize(width: 3_000, height: 4_000),
            zoom: 1.8,
            rotation: .degrees(degrees),
            center: CGPoint(x: 1_100, y: 2_600)
        )
        let layout = crop.layout(frameSide: 280)
        // 画面での描き方（拡大 → 画像の中心を軸に回転 → 移動）で、範囲の中心の画素が枠の中心（原点）にくるか
        let fromImageCenter = CGPoint(x: crop.center.x - 1_500, y: crop.center.y - 2_000)
        let scaled = CGPoint(x: fromImageCenter.x * layout.scale, y: fromImageCenter.y * layout.scale)
        let rotated = PhotoCrop.rotate(scaled, by: crop.rotation)
        #expect(abs(rotated.x + layout.offset.width) < 1e-6)
        #expect(abs(rotated.y + layout.offset.height) < 1e-6)
    }

    @Test("拡大・回転は枠の中心を軸にする（枠の中心に写る点は変わらない）")
    func zoomAndRotateKeepCenter() {
        let crop = PhotoCrop(
            imageSize: CGSize(width: 3_000, height: 4_000),
            zoom: 1.5,
            rotation: .zero,
            center: CGPoint(x: 1_300, y: 2_200)
        )
        let changed = crop.zoomed(by: 1.4).rotated(by: .degrees(20))
        #expect(changed.center == crop.center)
        #expect(abs(changed.zoom - 2.1) < Self.tolerance)
        #expect(abs(changed.rotation.degrees - 20) < 1e-9)
    }
}
