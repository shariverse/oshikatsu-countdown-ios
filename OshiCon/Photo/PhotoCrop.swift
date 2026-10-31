//
//  PhotoCrop.swift
//  OshiCon
//

import CoreGraphics
import Foundation
import SwiftUI

/// 写真の調整（拡大・縮小・移動・回転）で決める、丸の枠に写す正方形の範囲。
///
/// 座標は 2 つあり、変換はこの型の中だけで行う:
/// - 画像の座標: 向き（EXIF の Orientation）を反映した後の画像の画素。原点は左上、y は下向き
/// - 枠の座標: 調整画面の丸の枠（正方形）の pt。原点は枠の中心、y は下向き
///
/// 画面では、画像の中心を枠の中心に置き、`layout(frameSide:)` の拡大率で拡大し、画像の中心を軸に `rotation` だけ回し、
/// 移動量だけずらして描く（SwiftUI の `scaleEffect` → `rotationEffect` → `offset` の順）。
/// 状態は画面の大きさに左右されないよう、拡大率は「回転なしで画像の短い辺が枠にぴったり収まる大きさ」を 1 とした倍率で、
/// 位置は枠の中心に写る画像の点（画像の座標）で持つ。
nonisolated struct PhotoCrop: Equatable, Sendable {
    /// 切り抜く範囲の一辺の下限（画素）。これより狭く切り抜く拡大はさせない（粗くなりすぎないため）。
    static let minimumCropPixelLength: CGFloat = 360

    /// 向きを反映した後の画像の大きさ（画素）。取り込む写真の元の大きさ（表示用に縮める前）を渡す。
    /// 拡大の上限（`minimumCropPixelLength`）はこの画素で数える。
    let imageSize: CGSize
    /// 拡大率。1 で、回転なしのときに画像の短い辺が枠の一辺にぴったり収まる。
    var zoom: CGFloat
    /// 回転角。正の向きは画面で時計回り。360° を超えてもよい（範囲は正規化して求める）。
    var rotation: Angle
    /// 枠の中心に写る画像の点（画像の座標）。
    var center: CGPoint

    /// 写真全体が枠を覆う最小の大きさで、中央・回転なしの範囲。
    init(imageSize: CGSize) {
        let size = CGSize(width: max(imageSize.width, 1), height: max(imageSize.height, 1))
        self.imageSize = size
        zoom = 1
        rotation = .zero
        center = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    init(imageSize: CGSize, zoom: CGFloat, rotation: Angle, center: CGPoint) {
        self.init(imageSize: imageSize)
        self.zoom = zoom
        self.rotation = rotation
        self.center = center
    }

    // MARK: - 範囲の制約

    /// 画像の短い辺（画素）。
    var shortSide: CGFloat {
        min(imageSize.width, imageSize.height)
    }

    /// 今の回転角で枠を覆う最小の拡大率。
    ///
    /// 枠の正方形を画像の座標に戻すと角度 −θ だけ回った正方形になり、その外接矩形の一辺は「一辺 × (|cos θ| + |sin θ|)」。
    /// 凸多角形が軸に平行な矩形に収まるのは外接矩形が収まるときなので、外接矩形が画像の短い辺に収まる倍率が下限になる。
    var minimumZoom: CGFloat {
        Self.rotationFactor(rotation)
    }

    /// 拡大率の上限。切り抜く範囲の一辺が `minimumCropPixelLength` を下回らない倍率（画像が小さければ下限と同じ）。
    var maximumZoom: CGFloat {
        max(minimumZoom, shortSide / Self.minimumCropPixelLength)
    }

    /// 拡大率を上限・下限に収め、枠の隅が空かないよう位置を画像の中に寄せた範囲。回転角はそのまま。
    func clamped() -> Self {
        var result = self
        result.zoom = min(max(zoom, minimumZoom), maximumZoom)
        let halfExtent = result.region.side * Self.rotationFactor(rotation) / 2
        let limitX = max(imageSize.width / 2 - halfExtent, 0)
        let limitY = max(imageSize.height / 2 - halfExtent, 0)
        let dx = min(max(center.x - imageSize.width / 2, -limitX), limitX)
        let dy = min(max(center.y - imageSize.height / 2, -limitY), limitY)
        result.center = CGPoint(x: imageSize.width / 2 + dx, y: imageSize.height / 2 + dy)
        return result
    }

    // MARK: - 切り抜く範囲（画像の座標）

    /// 画像の座標で切り抜く正方形。
    nonisolated struct Region: Equatable, Sendable {
        /// 正方形の中心（画像の座標）。
        let center: CGPoint
        /// 正方形の一辺（画素）。
        let side: CGFloat
        /// 画像を回す角度（−180° より大きく 180° 以下に正規化）。y が下向きの座標で正は時計回り。
        /// 画像を中心の周りにこの角度だけ回して描くと、切り抜く正方形が軸に平行になる（画像の上では、正方形は逆向きに −`rotation` 傾いている）。
        let rotation: Angle

        /// 正方形の 4 つの隅（画像の座標）。枠の左上・右上・右下・左下の順。
        var corners: [CGPoint] {
            let half = side / 2
            let cosine = CGFloat(cos(rotation.radians))
            let sine = CGFloat(sin(rotation.radians))
            return [(-half, -half), (half, -half), (half, half), (-half, half)].map { x, y in
                // 枠の座標の点を画像の座標に戻す（−rotation だけ回す）
                CGPoint(x: center.x + x * cosine + y * sine, y: center.y - x * sine + y * cosine)
            }
        }

        /// 正方形を囲む、軸に平行な矩形（画像の座標）。
        var boundingBox: CGRect {
            let extent = side * PhotoCrop.rotationFactor(rotation)
            return CGRect(x: center.x - extent / 2, y: center.y - extent / 2, width: extent, height: extent)
        }
    }

    /// 切り抜く正方形（画像の座標）。補正していない値でもそのまま求める（補正は `clamped()`）。
    var region: Region {
        Region(center: center, side: shortSide / max(zoom, .leastNonzeroMagnitude), rotation: Self.normalized(rotation))
    }

    // MARK: - 画面の枠への配置

    /// 画面の枠（一辺 `frameSide` pt）に描くときの、画像の拡大率（pt / 画素）と、画像の中心を枠の中心からずらす量（pt）。
    func layout(frameSide: CGFloat) -> (scale: CGFloat, offset: CGSize) {
        let scale = pointsPerPixel(frameSide: frameSide)
        // 画像の中心から見た枠の中心の点を、拡大・回転して枠の座標に移し、向きを反転したものが画像の中心の位置
        let delta = CGPoint(x: imageSize.width / 2 - center.x, y: imageSize.height / 2 - center.y)
        let rotated = Self.rotate(delta, by: rotation)
        return (scale, CGSize(width: rotated.x * scale, height: rotated.y * scale))
    }

    /// 枠の上で画像を `translation`（pt）だけ動かした範囲。補正はしない。
    func dragged(by translation: CGSize, frameSide: CGFloat) -> Self {
        let scale = pointsPerPixel(frameSide: frameSide)
        let delta = Self.rotate(CGPoint(x: translation.width / scale, y: translation.height / scale), by: -rotation)
        var result = self
        result.center = CGPoint(x: center.x - delta.x, y: center.y - delta.y)
        return result
    }

    /// 枠の中心を軸に `factor` 倍に拡大した範囲。補正はしない。
    func zoomed(by factor: CGFloat) -> Self {
        var result = self
        result.zoom = zoom * factor
        return result
    }

    /// 枠の中心を軸に `angle` だけ回した範囲。補正はしない。
    func rotated(by angle: Angle) -> Self {
        var result = self
        result.rotation = rotation + angle
        return result
    }

    private func pointsPerPixel(frameSide: CGFloat) -> CGFloat {
        max(zoom, .leastNonzeroMagnitude) * frameSide / shortSide
    }

    /// 調整画面の「完了」で返った範囲が、開いたときの範囲（`initial` を補正したもの）から変わっていないか。
    /// 回転は同じ見た目なら同じとみなす（「元に戻す」で何周か回したあとも）。
    func isUnchanged(from initial: Self) -> Bool {
        var current = clamped()
        current.rotation = Self.normalized(current.rotation)
        var original = initial.clamped()
        original.rotation = Self.normalized(original.rotation)
        let tolerance: CGFloat = 1e-6
        return imageSize == original.imageSize
            && abs(current.zoom - original.zoom) < tolerance
            && abs(current.rotation.radians - original.rotation.radians) < tolerance
            && abs(current.center.x - original.center.x) < tolerance
            && abs(current.center.y - original.center.y) < tolerance
    }

    // MARK: - 計算の部品

    /// |cos θ| + |sin θ|。回転した正方形の外接矩形の一辺の、元の一辺に対する倍率（1 以上 √2 以下）。
    static func rotationFactor(_ angle: Angle) -> CGFloat {
        CGFloat(abs(cos(angle.radians)) + abs(sin(angle.radians)))
    }

    /// −180° より大きく 180° 以下にそろえた角度。
    static func normalized(_ angle: Angle) -> Angle {
        var radians = angle.radians.truncatingRemainder(dividingBy: 2 * .pi)
        if radians > .pi {
            radians -= 2 * .pi
        } else if radians <= -.pi {
            radians += 2 * .pi
        }
        return .radians(radians)
    }

    /// 点を原点の周りに `angle` だけ回す（y が下向きの座標で、正の角度は時計回り）。
    static func rotate(_ point: CGPoint, by angle: Angle) -> CGPoint {
        let cosine = CGFloat(cos(angle.radians))
        let sine = CGFloat(sin(angle.radians))
        return CGPoint(x: point.x * cosine - point.y * sine, y: point.x * sine + point.y * cosine)
    }
}
