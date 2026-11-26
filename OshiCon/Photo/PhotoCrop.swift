//
//  PhotoCrop.swift
//  OshiCon
//

import CoreGraphics
import Foundation
import SwiftUI

/// 写真の調整（拡大・縮小・移動・回転）で決める、枠に写す長方形の範囲。推しの丸は正方形（`aspectRatio` が 1）、背景の写真は縦長。
///
/// 座標は 2 つあり、変換はこの型の中だけで行う:
/// - 画像の座標: 向き（EXIF の Orientation）を反映した後の画像の画素。原点は左上、y は下向き
/// - 枠の座標: 調整画面の枠（縦横比 `aspectRatio` の長方形）の pt。原点は枠の中心、y は下向き
///
/// 画面では、画像の中心を枠の中心に置き、`layout(frameSize:)` の拡大率で拡大し、画像の中心を軸に `rotation` だけ回し、
/// 移動量だけずらして描く（SwiftUI の `scaleEffect` → `rotationEffect` → `offset` の順）。
/// 状態は画面の大きさに左右されないよう、拡大率は「回転なしで枠が画像にぴったり収まる大きさ」を 1 とした倍率で、
/// 位置は枠の中心に写る画像の点（画像の座標）で持つ。
nonisolated struct PhotoCrop: Equatable, Sendable {
    /// 切り抜く範囲の短い辺の下限（画素）。これより狭く切り抜く拡大はさせない（粗くなりすぎないため）。
    static let minimumCropPixelLength: CGFloat = 360
    /// 背景の写真の枠の縦横比（幅 ÷ 高さ）。iPhone の画面の比率（約 9:19.5）の縦長。
    static let backgroundAspectRatio: CGFloat = 9 / 19.5

    /// 向きを反映した後の画像の大きさ（画素）。取り込む写真の元の大きさ（表示用に縮める前）を渡す。
    /// 拡大の上限（`minimumCropPixelLength`）はこの画素で数える。
    let imageSize: CGSize
    /// 枠の縦横比（幅 ÷ 高さ）。1 で正方形（推しの丸）。
    let aspectRatio: CGFloat
    /// 拡大率。1 で、回転なしのときに枠が画像にぴったり収まる（正方形の枠では、画像の短い辺が枠の一辺にぴったり収まる）。
    var zoom: CGFloat
    /// 回転角。正の向きは画面で時計回り。360° を超えてもよい（範囲は正規化して求める）。
    var rotation: Angle
    /// 枠の中心に写る画像の点（画像の座標）。
    var center: CGPoint

    /// 写真全体が枠を覆う最小の大きさで、中央・回転なしの範囲。`aspectRatio` は枠の縦横比（幅 ÷ 高さ。既定は正方形）。
    init(imageSize: CGSize, aspectRatio: CGFloat = 1) {
        let size = CGSize(width: max(imageSize.width, 1), height: max(imageSize.height, 1))
        self.imageSize = size
        self.aspectRatio = aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 1
        zoom = 1
        rotation = .zero
        center = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    init(imageSize: CGSize, aspectRatio: CGFloat = 1, zoom: CGFloat, rotation: Angle, center: CGPoint) {
        self.init(imageSize: imageSize, aspectRatio: aspectRatio)
        self.zoom = zoom
        self.rotation = rotation
        self.center = center
    }

    // MARK: - 範囲の制約

    /// 画像の短い辺（画素）。
    var shortSide: CGFloat {
        min(imageSize.width, imageSize.height)
    }

    /// 拡大率 1・回転なしの枠の大きさ（画像の座標）。枠の縦横比のまま画像に収まる最大の長方形。
    var baseSize: CGSize {
        if imageSize.width / imageSize.height > aspectRatio {
            CGSize(width: imageSize.height * aspectRatio, height: imageSize.height)
        } else {
            CGSize(width: imageSize.width, height: imageSize.width / aspectRatio)
        }
    }

    /// 今の回転角で枠を覆う最小の拡大率。
    ///
    /// 枠の長方形（幅 w・高さ h）を画像の座標に戻すと角度 −θ だけ回った長方形になり、その外接矩形は
    /// 幅 w|cos θ| + h|sin θ|・高さ w|sin θ| + h|cos θ|。凸多角形が軸に平行な矩形に収まるのは外接矩形が収まるときなので、
    /// 外接矩形の幅と高さが画像に収まる倍率が下限になる（正方形の枠では |cos θ| + |sin θ|）。
    var minimumZoom: CGFloat {
        let extent = Self.boundingSize(of: baseSize, rotatedBy: rotation)
        return max(extent.width / imageSize.width, extent.height / imageSize.height)
    }

    /// 拡大率の上限。切り抜く範囲の短い辺が `minimumCropPixelLength` を下回らない倍率（画像が小さければ下限と同じ）。
    var maximumZoom: CGFloat {
        max(minimumZoom, min(baseSize.width, baseSize.height) / Self.minimumCropPixelLength)
    }

    /// 拡大率を上限・下限に収め、枠の隅が空かないよう位置を画像の中に寄せた範囲。回転角はそのまま。
    func clamped() -> Self {
        var result = self
        result.zoom = min(max(zoom, minimumZoom), maximumZoom)
        let extent = result.region.boundingBox.size
        let limitX = max(imageSize.width / 2 - extent.width / 2, 0)
        let limitY = max(imageSize.height / 2 - extent.height / 2, 0)
        let dx = min(max(center.x - imageSize.width / 2, -limitX), limitX)
        let dy = min(max(center.y - imageSize.height / 2, -limitY), limitY)
        result.center = CGPoint(x: imageSize.width / 2 + dx, y: imageSize.height / 2 + dy)
        return result
    }

    // MARK: - 切り抜く範囲（画像の座標）

    /// 画像の座標で切り抜く長方形。
    nonisolated struct Region: Equatable, Sendable {
        /// 長方形の中心（画像の座標）。
        let center: CGPoint
        /// 長方形の幅と高さ（画素。枠の向きで数える）。
        let size: CGSize
        /// 画像を回す角度（−180° より大きく 180° 以下に正規化）。y が下向きの座標で正は時計回り。
        /// 画像を中心の周りにこの角度だけ回して描くと、切り抜く長方形が軸に平行になる（画像の上では、長方形は逆向きに −`rotation` 傾いている）。
        let rotation: Angle

        /// 正方形の枠の一辺（画素）。長方形の枠では幅。
        var side: CGFloat {
            size.width
        }

        /// 長方形の 4 つの隅（画像の座標）。枠の左上・右上・右下・左下の順。
        var corners: [CGPoint] {
            let halfWidth = size.width / 2
            let halfHeight = size.height / 2
            let cosine = CGFloat(cos(rotation.radians))
            let sine = CGFloat(sin(rotation.radians))
            let offsets = [(-halfWidth, -halfHeight), (halfWidth, -halfHeight), (halfWidth, halfHeight), (-halfWidth, halfHeight)]
            return offsets.map { x, y in
                // 枠の座標の点を画像の座標に戻す（−rotation だけ回す）
                CGPoint(x: center.x + x * cosine + y * sine, y: center.y - x * sine + y * cosine)
            }
        }

        /// 長方形を囲む、軸に平行な矩形（画像の座標）。
        var boundingBox: CGRect {
            let extent = PhotoCrop.boundingSize(of: size, rotatedBy: rotation)
            return CGRect(origin: CGPoint(x: center.x - extent.width / 2, y: center.y - extent.height / 2), size: extent)
        }
    }

    /// 切り抜く長方形（画像の座標）。補正していない値でもそのまま求める（補正は `clamped()`）。
    var region: Region {
        let scale = max(zoom, .leastNonzeroMagnitude)
        let base = baseSize
        return Region(
            center: center,
            size: CGSize(width: base.width / scale, height: base.height / scale),
            rotation: Self.normalized(rotation)
        )
    }

    // MARK: - 画面の枠への配置

    /// 画面の枠（大きさ `frameSize` pt。縦横比は `aspectRatio`）に描くときの、画像の拡大率（pt / 画素）と、画像の中心を枠の中心からずらす量（pt）。
    func layout(frameSize: CGSize) -> (scale: CGFloat, offset: CGSize) {
        let scale = pointsPerPixel(frameWidth: frameSize.width)
        // 画像の中心から見た枠の中心の点を、拡大・回転して枠の座標に移し、向きを反転したものが画像の中心の位置
        let delta = CGPoint(x: imageSize.width / 2 - center.x, y: imageSize.height / 2 - center.y)
        let rotated = Self.rotate(delta, by: rotation)
        return (scale, CGSize(width: rotated.x * scale, height: rotated.y * scale))
    }

    /// 正方形の枠（一辺 `frameSide` pt）に描くときの配置。
    func layout(frameSide: CGFloat) -> (scale: CGFloat, offset: CGSize) {
        layout(frameSize: CGSize(width: frameSide, height: frameSide))
    }

    /// 枠（大きさ `frameSize` pt）の上で画像を `translation`（pt）だけ動かした範囲。補正はしない。
    func dragged(by translation: CGSize, frameSize: CGSize) -> Self {
        let scale = pointsPerPixel(frameWidth: frameSize.width)
        let delta = Self.rotate(CGPoint(x: translation.width / scale, y: translation.height / scale), by: -rotation)
        var result = self
        result.center = CGPoint(x: center.x - delta.x, y: center.y - delta.y)
        return result
    }

    /// 正方形の枠（一辺 `frameSide` pt）の上で画像を動かした範囲。補正はしない。
    func dragged(by translation: CGSize, frameSide: CGFloat) -> Self {
        dragged(by: translation, frameSize: CGSize(width: frameSide, height: frameSide))
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

    /// 枠の幅（pt）を、切り抜く範囲の幅（画素）で割った倍率。
    private func pointsPerPixel(frameWidth: CGFloat) -> CGFloat {
        max(zoom, .leastNonzeroMagnitude) * frameWidth / baseSize.width
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
            && aspectRatio == original.aspectRatio
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

    /// 幅と高さが `size` の長方形を `angle` だけ回したときの、外接矩形の幅と高さ。
    static func boundingSize(of size: CGSize, rotatedBy angle: Angle) -> CGSize {
        let cosine = CGFloat(abs(cos(angle.radians)))
        let sine = CGFloat(abs(sin(angle.radians)))
        return CGSize(
            width: size.width * cosine + size.height * sine,
            height: size.width * sine + size.height * cosine
        )
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
